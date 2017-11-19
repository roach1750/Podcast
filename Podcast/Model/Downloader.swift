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

class Downloader: NSObject {
    
    
    
    ///need to fix this for apostrophe 
    
    func searchForPodcast(searchString: String) {
        let correctedSearchString = searchString.replacingOccurrences(of: " ", with: "+")
        let link = "https://itunes.apple.com/search?term=+" + correctedSearchString + "+&entity=podcast"
        let url = URL(string: link)
        
        Alamofire.request(url!, method: .post, parameters: nil, encoding: JSONEncoding.default)
            .responseJSON { response in
                //to get status code
                if let status = response.response?.statusCode {
                    switch(status){
                    case 201:
                        print("example success")
                    default:
                        print("error with response status: \(status)")
                    }
                }
                //to get JSON return value
                if let result = response.result.value {
                    let JSON = result as! NSDictionary
                    print("Found: " + String(describing: JSON["resultCount"]!) + " results")
                    let resultCount = JSON["resultCount"] as! Int
                    if resultCount == 0 {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "noSearchResultsFound"), object: nil)
                        return
                    }
                    else {
                    for result in JSON.value(forKey: "results") as! [NSDictionary] {
                        let id = String(result["collectionId"] as! Int)
                        if RealmInteractor().checkIfPodcastExists(id: id) == false {
                            let podcast = Podcast()
                            podcast.name = result["collectionName"] as? String
                            podcast.artworkLink100x100 = result["artworkUrl100"] as? String
                            podcast.artworkLink600x600 = result["artworkUrl600"] as? String
                            podcast.iD = String(result["collectionId"] as! Int)
                            podcast.isSubscribed = false
                            podcast.isSearchResult = true
                            podcast.downloadLink = result["feedUrl"] as? String
                            let RI = RealmInteractor()
                            RI.savePodcast(podcast: podcast)
                        }
                        else {
                            RealmInteractor().setPodcastToSearchResult(id: id)
                        }
                    }
                    
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "searchResultsFound"), object: nil)
                    
                }
                }
                
        }
    }
    
    func downloadImageForPodcast(podcastID: String, highRes: Bool) {
        
        let podcast = RealmInteractor().fetchPodcast(withID: podcastID)
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(podcastID+".png")
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        let link = highRes == true ? podcast.artworkLink600x600 : podcast.artworkLink100x100
        Alamofire.download(link!, to: destination)
            .downloadProgress(closure: { (progress) in
                
            })
            .response { response in
                if response.error == nil {
                    if let dataPath = response.destinationURL {
                        do {
                            let imageData = try Data(contentsOf: dataPath)
                            if highRes == true {
                                RealmInteractor().updatePodcastArtwork(podcast: podcast, artwork: imageData, highRes: true)
                            }
                            else {
                                RealmInteractor().updatePodcastArtwork(podcast: podcast, artwork: imageData, highRes: false)
                            }
                            self.deleteTempImageFileForPodcast(podcast: podcast)
                        }
                        catch let error {
                            print("Error in downloading artwork: \(error.localizedDescription)")
                        }
                    }
                }
        }
    }
    
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
    func downloadPodcastData(podcast: Podcast, completion: @escaping(Bool) -> Void) {
        print("Starting to download podcast data")
        let RI = RealmInteractor() 
        let link = podcast.downloadLink!
        
        let feedURL = URL(string: link)
        let parser = FeedParser(URL: feedURL!)
        parser?.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
            print("Found \(String(describing: result.rssFeed?.items?.count)) episodes")
            
            var newEpisodes = false
            for item in (result.rssFeed?.items)! {
                let guid = item.guid!.value
                
                if RealmInteractor().checkIfPodcastEpisodeExists(guid: guid!) == false {
                    let episode = Episode()
                    newEpisodes = true
                    episode.guid = item.guid!.value //Unique ID
                    episode.title = item.title //Title
                    episode.descript = item.description?.replacingOccurrences(of: "</p>", with: "").replacingOccurrences(of: "<p>", with: "").replacingOccurrences(of: "&nbsp;", with: "").replacingOccurrences(of: "&amp;", with: "") //Title without the segment
                    episode.publishedDate =  item.pubDate //Publish Date
                    if let duration = item.iTunes?.iTunesDuration {
                        episode.duration = duration  //duration in sections
                    }
                    episode.downloadURL =  item.enclosure?.attributes?.url //this is the download URL
                    episode.fileSize =  Double((item.enclosure?.attributes?.length)!) //size in bytes
                    

                    DispatchQueue.main.async {
                        RI.saveEpisodeForPodcast(episode: episode, podcast: podcast)
                    }
                }
                //                print(item.link) //Link to website, not sure this is useful?
                //                print(item.enclosure?.attributes?.type) //audio type
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "newEpisodeListDownloaded"), object: nil)
            }
            
            if newEpisodes == true {
                completion(true)
            }
            else {
                completion(false)
            }
            

        }

    }
    
    
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
