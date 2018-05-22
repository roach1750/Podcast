//
//  PodcastDownloader.swift
//  Podcast
//
//  Created by Andrew Roach on 8/9/17.
//  Copyright © 2017 Andrew Roach. All rights reserved.
//

import UIKit
import Alamofire
import FeedKit
import AVFoundation
import RealmSwift

class Downloader: NSObject {
    
    
    func searchForPodcast(searchString: String) {
        let correctedSearchString = searchString.replacingOccurrences(of: " ", with: "+")
        let link = "https://itunes.apple.com/search?term=+" + correctedSearchString + "+&entity=podcast"
        downloadPodcast(link: link, podcastType: .SearchResults)
    }
    
    func downloadTopPodcasts() {
        let link = "https://rss.itunes.apple.com/api/v1/us/podcasts/top-podcasts/all/10/explicit.json"
        downloadPodcast(link: link, podcastType: .Top)
    }
    
    let defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?
    
    fileprivate func downloadPodcast(link: String, podcastType: PodcastType) {
        dataTask?.cancel()
        guard let url = URL(string: link) else { return }
        dataTask = defaultSession.dataTask(with: url) { data, response, error in
            if let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                switch podcastType {
                case .SearchResults: self.decodePodcastSearchResults(data)
                case .Top: self.decodeTopPodcast(data)
                case .Individual: self.decodeIndividualPodcastSearchResults(data)
                }
            }
        }
        dataTask?.resume()
    }

    //SEARCHRESULTS
    fileprivate func decodePodcastSearchResults(_ data: Data) {
        let results = try! JSONDecoder().decode(iTunesPodcastResults.self, from: data)
        for jSONPodcast in results.results {
            convertJSONPodcastToPodcast(podcastToConvert: jSONPodcast)
        }
    }

    //INDIVIDUAL
    fileprivate func decodeIndividualPodcastSearchResults(_ data: Data) {
        let results = try! JSONDecoder().decode(iTunesPodcastResults.self, from: data)
        convertJSONPodcastToPodcast(podcastToConvert: results.results.first!)
    }
    
    func convertJSONPodcastToPodcast(podcastToConvert: iTunesPodcastResults.JSONPodcast) {
        let newPodcast = Podcast()
        newPodcast.name = podcastToConvert.collectionName
        newPodcast.artworkLink100x100 = podcastToConvert.artworkUrl100
        newPodcast.artworkLink600x600 = podcastToConvert.artworkUrl600
        newPodcast.iD = String(podcastToConvert.collectionId!)
        newPodcast.isSubscribed = false
        newPodcast.isSearchResult = true
        newPodcast.downloadLink = podcastToConvert.feedUrl
        RealmInteractor().savePodcast(podcast: newPodcast)
    }
    
    //TOP
    fileprivate func decodeTopPodcast(_ data: Data) {
        let results = try! JSONDecoder().decode([String: iTunesTopPodcast].self, from: data)
        for (index, topPodcast) in (results["feed"]?.results)!.enumerated() {
            let newTopPodcast = TopPodcast()
            newTopPodcast.name = topPodcast.name
            newTopPodcast.iD = topPodcast.id!
            newTopPodcast.artworkLink100x100 = topPodcast.artworkUrl100
            newTopPodcast.ranking = index + 1
            RealmInteractor().saveTopPodcast(topPodcast: newTopPodcast)
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "TopPodcastsDownloaded"), object: nil)
        }
    }
    
    
    //CONVERSION OF TOPPODCAST TO PODCAST
    func convertTopPodcastToPodcast(podcastToConvert: TopPodcast) {
        let link = "https://itunes.apple.com/lookup?id=" + podcastToConvert.iD
        downloadPodcast(link: link, podcastType: .Individual)
    }

    //DOWNLOAD IMAGE FOR PODCAST
    func downloadImageForPodcast(podcast: Podcast, highRes: Bool) {
        if highRes == true {
            downloadImage(imageLink: podcast.artworkLink600x600!) { (result) in
                DispatchQueue.main.async {
                    RealmInteractor().updatePodcastArtwork(podcast: podcast, artwork: result, highRes: true)
                }
            }
        }
        else {
            downloadImage(imageLink: podcast.artworkLink100x100!) { (result) in
                DispatchQueue.main.async {
                    RealmInteractor().updatePodcastArtwork(podcast: podcast, artwork: result, highRes: false)
                }
            }
        }
    }
    
    func downloadImageForTopPodcast(topPodcast: TopPodcast) {
        downloadImage(imageLink: topPodcast.artworkLink100x100!) { (result) in
            DispatchQueue.main.async {
                RealmInteractor().updatePodcastArtwork(topPodcast: topPodcast, artwork: result)
            }
        }
    }
    
    fileprivate func downloadImage(imageLink:String, completion: @escaping(Data) -> Void) {
        dataTask?.cancel()
        guard let url = URL(string: imageLink) else { return }
        dataTask = defaultSession.dataTask(with: url) { data, response, error in
            completion(data!)
        }
        dataTask?.resume()
    }
    
    //Download Episodes for Podcast
    
    func downloadPodcastData(podcast: Podcast) {
        print("downloading episodes called")
        
        let RI = RealmInteractor()
        let link = podcast.downloadLink!
        let feedURL = URL(string: link)
        let parser = FeedParser(URL: feedURL!)
        let treadPodcastReference = ThreadSafeReference(to: podcast)
//        print("⚡️: \(Thread.current)" + "🏭: \(OperationQueue.current?.underlyingQueue?.label ?? "None")")

        parser?.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
            print("Found \(String(describing: result.rssFeed?.items?.count)) episodes")
            
            let realm = try! Realm()
            guard let podcast = realm.resolve(treadPodcastReference) else {
                print("Tread Problem")
                fatalError()
            }
            
//            var newEpisodes = false
            for item in (result.rssFeed?.items)! {
                let guid = item.guid!.value
                if RealmInteractor().checkIfPodcastEpisodeExists(guid: guid!) == false {
                    let episode = Episode()
//                    newEpisodes = true
                    episode.guid = item.guid!.value //Unique ID
                    episode.title = item.title //Title
                    episode.descript = self.trimEpisodeDescription(description: item.description!)
                    episode.publishedDate =  item.pubDate //Publish Date
                    if let duration = item.iTunes?.iTunesDuration {
                        episode.estimatedDuration = duration  //duration in seconds
                    }
                    episode.downloadURL =  item.enclosure?.attributes?.url //this is the download URL
                    if let fileSize = item.enclosure?.attributes?.length  {
                        episode.fileSize = Double(fileSize)
                    }
                    episode.podcast = podcast
                    episode.podcastID = podcast.iD
                    RI.saveEpisode(episode: episode)
                }
            }
            
            DispatchQueue.main.async {
                print("Send Notification")
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "newEpisodeListDownloaded"), object: nil)
            }
        }
        
    }
    
    
    func trimEpisodeDescription(description: String) -> String {
        return description.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "&nbsp;", with: "").replacingOccurrences(of: "&amp;", with: "")
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    ///////OLD STUFF

    
    func searchPodcastInformation() {
        let link = "https://itunes.apple.com/us/podcast/couples-therapy-with-candice-and-casey/id1380252026?mt=2&uo=4"
                    
        let url = URL(string: link)!
        Alamofire.request(url).responseString { response in
            
            print(response)
                
        }
    }
    
    
    ///need to fix this for apostrophe
//    func searchForPodcast(searchString: String) {
//        let correctedSearchString = searchString.replacingOccurrences(of: " ", with: "+")
//        let link = "https://itunes.apple.com/search?term=+" + correctedSearchString + "+&entity=podcast"
//        let url = URL(string: link)
//
//        Alamofire.request(url!, method: .post, parameters: nil, encoding: JSONEncoding.default)
//            .responseJSON { response in
//                //to get status code
//                if let status = response.response?.statusCode {
//                    switch(status){
//                    case 201:
//                        print("example success")
//                    default:
//                        print("error with response status: \(status)")
//                    }
//                }
//                //to get JSON return value
//                if let result = response.result.value {
//                    let JSON = result as! NSDictionary
//                    print("Found: " + String(describing: JSON["resultCount"]!) + " results")
//                    let resultCount = JSON["resultCount"] as! Int
//                    if resultCount == 0 {
//                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "noSearchResultsFound"), object: nil)
//                        return
//                    }
//                    else {
//                    for result in JSON.value(forKey: "results") as! [NSDictionary] {
//                        print(result)
//                        let id = String(result["collectionId"] as! Int)
//                        if RealmInteractor().checkIfPodcastExists(id: id) == false {
//                            let podcast = Podcast()
//                            podcast.name = result["collectionName"] as? String
//                            podcast.artworkLink100x100 = result["artworkUrl100"] as? String
//                            podcast.artworkLink600x600 = result["artworkUrl600"] as? String
//                            podcast.iD = String(result["collectionId"] as! Int)
//                            podcast.isSubscribed = false
//                            podcast.isSearchResult = true
//                            podcast.downloadLink = result["feedUrl"] as? String
//                            let RI = RealmInteractor()
//                            RI.savePodcast(podcast: podcast)
//                        }
//                        else {
//                            RealmInteractor().setPodcastToSearchResult(id: id)
//                        }
//                    }
//                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "searchResultsFound"), object: nil)
//                }
//            }
//        }
//    }
    
//    func downloadImageForPodcast(podcastID: String, highRes: Bool) {
//
//        let podcast = RealmInteractor().fetchPodcast(withID: podcastID)
//        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
//            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//            let fileURL = documentsURL.appendingPathComponent(podcastID+".png")
//            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
//        }
//
//        let link = highRes == true ? podcast.artworkLink600x600 : podcast.artworkLink100x100
//        Alamofire.download(link!, to: destination)
//            .downloadProgress(closure: { (progress) in
//
//            })
//            .response { response in
//                if response.error == nil {
//                    if let dataPath = response.destinationURL {
//                        do {
//                            let imageData = try Data(contentsOf: dataPath)
//                            if highRes == true {
//                                RealmInteractor().updatePodcastArtwork(podcast: podcast, artwork: imageData, highRes: true)
//                            }
//                            else {
//                                RealmInteractor().updatePodcastArtwork(podcast: podcast, artwork: imageData, highRes: false)
//                            }
//                            self.deleteTempImageFileForPodcast(podcast: podcast)
//                        }
//                        catch let error {
//                            print("Error in downloading artwork: \(error.localizedDescription)")
//                        }
//                    }
//                }
//        }
//    }
    
    func deleteTempImageFileForPodcast(podcast: Podcast) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(podcast.iD+".png")
        
        do {
            try FileManager.default.removeItem(at: fileURL)
        }
        catch {
            print("Error in trying to delete old artwork: \(error.localizedDescription)")

        }
    }
    
    
    //This is all the episodes, this is what should refresh
    
    
    func downloadInvidualEpisode(episode: Episode) {
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("pig.png")
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        print("starting download")
        
        Alamofire.download(episode.downloadURL!, to: destination)
            
            .downloadProgress(closure: { (progress) in
                
                let userInfo = ["progress": progress.fractionCompleted, "prodcastID" : episode.guid! ] as [String : Any]
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "episodeDownloadInProgress"), object: nil, userInfo: userInfo)
                
                print(progress)
            
            })
            
            .response { response in
                
                if response.error == nil {
                    let dataPath = response.destinationURL
                    let episodeData = try! Data(contentsOf: dataPath!)
                    //                    let bcf = ByteCountFormatter()
                    //                    bcf.allowedUnits = [.useMB]
                    //                    bcf.countStyle = .file
                    //                    let string = bcf.string(fromByteCount: Int64(length))
                    //                    print(string)
                    //
                    
                    //Need to check if it is bigger than 16MB then split it into chuncks, probably like 15MB chuncks
                    
                    let dataArray = self.splitDataIntoArray(data: episodeData)
                    
                    
                    let RI = RealmInteractor()
                    RI.addEpisodeAudioToEpisode(episode: episode, audio: dataArray)
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "episodeDownloaded"), object: nil)
                    }
                }
        }
    }
    
    func splitDataIntoArray(data: Data) -> [Data]{
        
        let length = data.count
        let chunkSize = 1048576 * 1      // 1mb chunk sizes
        var offset = 0
        var dataArray = [Data]()
        repeat {
            // get the length of the chunk
            let thisChunkSize = ((length - offset) > chunkSize) ? chunkSize : (length - offset);
            
            // get the chunk
            let chunk = data.subdata(in: offset..<offset + thisChunkSize )
            
            dataArray.append(chunk)
            
            offset += thisChunkSize;
            
        } while (offset < length)
        
        return dataArray
    }
    
    
    
}



extension Thread {
    class func printCurrent() {
        print("\r⚡️: \(Thread.current)\r" + "🏭: \(OperationQueue.current?.underlyingQueue?.label ?? "None")\r")
    }
}
