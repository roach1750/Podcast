//
//  PodcastDownloader.swift
//  Podcast
//
//  Created by Andrew Roach on 8/9/17.
//  Copyright © 2017 Andrew Roach. All rights reserved.
//

import UIKit
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
        let link = "https://rss.itunes.apple.com/api/v1/us/podcasts/top-podcasts/all/50/explicit.json"
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
    
    var topPodcasts: [TopPodcast]?
    
    //TOP
    fileprivate func decodeTopPodcast(_ data: Data) {
        topPodcasts = [TopPodcast]()
        let results = try! JSONDecoder().decode([String: iTunesTopPodcast].self, from: data)
        for (index, topPodcast) in (results["feed"]?.results)!.enumerated() {
            let newTopPodcast = TopPodcast()
            newTopPodcast.name = topPodcast.name
            newTopPodcast.iD = topPodcast.id!
            newTopPodcast.artworkLink100x100 = topPodcast.artworkUrl100
            newTopPodcast.ranking = index + 1
            topPodcasts?.append(newTopPodcast)
            
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "TopPodcastsDownloaded"), object: nil)
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
    
    //DOWNLOAD IMAGE FOR TOP PODCAST
    func downloadImageForTopPodcast(topPodcast: TopPodcast, completion: @escaping(Data) -> Void) {
        downloadImage(imageLink: topPodcast.artworkLink100x100!) { (result) in
            completion(result)
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
    func downloadPodcastData(podcast: Podcast, completion: (() -> Void)?) {
        print("downloading episodes called")
        
        let RI = RealmInteractor()
        let link = podcast.downloadLink! //NEED TO CHECK IF THIS IS NIL 
        let feedURL = URL(string: link)
        let parser = FeedParser(URL: feedURL!)
        let treadPodcastReference = ThreadSafeReference(to: podcast)
//        print("⚡️: \(Thread.current)" + "🏭: \(OperationQueue.current?.underlyingQueue?.label ?? "None")")

        parser?.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
            print("Downloaded \(String(describing: result.rssFeed!.items!.count)) episodes")
            
            let startTime = Date()
            let realm = try! Realm()
            guard let podcast = realm.resolve(treadPodcastReference) else {
                print("Tread Problem")
                fatalError()
            }
            var episodes = [Episode]()
            for item in (result.rssFeed?.items)! {
                let guid = item.guid!.value
                if RealmInteractor().checkIfPodcastEpisodeExists(guid: guid!) == false {
                    let episode = Episode()
                    episode.guid = item.guid!.value //Unique ID
                    episode.title = item.title //Title
                    episode.descript = self.trimEpisodeDescription(description: item.description)
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
//                    RI.saveEpisode(episode: episode)
                    episodes.append(episode)
                }
            }
            
            RI.saveEpisodes(episodes: episodes)
            
            let endTime = Date()
            print("Added to database, It took: \(endTime.timeIntervalSince(startTime)) seconds to save the episodes")
            
            DispatchQueue.main.async {
                if completion != nil {
                    completion!()
                }
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "newEpisodeListDownloaded"), object: nil)
            }
        }
        
    }
    
    
    func trimEpisodeDescription(description: String?) -> String {
        if description != nil {
            return description!.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "&nbsp;", with: "").replacingOccurrences(of: "&amp;", with: "")
        }
        return ""
    }
    
    
   
    
    
}




