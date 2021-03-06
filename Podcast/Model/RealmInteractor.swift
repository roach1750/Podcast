//
//  RealmInteractor.swift
//  Podcast
//
//  Created by Andrew Roach on 8/9/17.
//  Copyright © 2017 Andrew Roach. All rights reserved.
//

import UIKit
import RealmSwift

class RealmInteractor: NSObject {

    
    func savePodcast(podcast: Podcast) {
        let realm = try! Realm()
        try! realm.write {
            realm.create(Podcast.self, value: podcast, update: true)
        }
    }
    
    func saveEpisode(episode: Episode) {
//        print("saveEpisodeCalled Actual Method - ⚡️: \(Thread.current)" + "🏭: \(OperationQueue.current?.underlyingQueue?.label ?? "None")")
        let realm = try! Realm()
        try! realm.write {
            realm.create(Episode.self, value: episode, update: true)
        }
    }
    

    //NEW
    func saveEpisodes(episodes: [Episode]) {
        let realm = try! Realm()
        try! realm.write {
            realm.add(episodes, update: true)
        }
    }
    
    func updatePodcastArtwork(podcast:Podcast, artwork:Data, highRes: Bool) {        
        let realm = try! Realm()
        if highRes == true {
            try! realm.write {
                podcast.artwork600x600 = artwork
            }
        }
        else {
            try! realm.write {
                podcast.artwork100x100 = artwork
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "podcastArtworkDownloaded"), object: nil)
        print("new artwork is saved to realm")
    }
    
    func fetchAllPodcast() -> [Podcast] {
        let realm = try! Realm()
        let results = Array(realm.objects(Podcast.self))
        return results
    }
    
    func checkIfPodcastExists(id: String) -> Bool {
        let realm = try! Realm()
        let predicate = NSPredicate(format: "iD == %@", id)
        let results = Array(realm.objects(Podcast.self).filter(predicate))
        if results.count > 0 {
            return true
        }
        return false
    }
    
    func checkIfPodcastEpisodeExists(guid: String) -> Bool {
        
        let realm = try! Realm()
        let predicate = NSPredicate(format: "guid == %@", guid)
        let results = Array(realm.objects(Episode.self).filter(predicate))
        if results.count > 0 {
            return true
        }
        return false
    }
    
    func markAllPodcastAsNotSearchResults() {
        let realm = try! Realm()
        let results = Array(realm.objects(Podcast.self))
        for podcast in results {
            if podcast.isSearchResult == true {
                try! realm.write {
                    podcast.isSearchResult = false
                }
            }
        }
    }
    
    func markEpisodeAsNowPlaying(episode: Episode) {
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "isNowPlayingEpisode == true")
        let results = Array(realm.objects(Episode.self).filter(predicate))
        for object in results {
            try! realm.write {
                object.isNowPlayingEpisode = false 
            }
        }
        
        
        try! realm.write {
            episode.isNowPlayingEpisode = true
        }
        
        
        
        
    }
    
    func markAllEpisodesAsNotPlaying() {
        let realm = try! Realm()
        let results = Array(realm.objects(Episode.self))
        for episode in results {
            if episode.isNowPlayingEpisode == true {
                try! realm.write {
                    episode.isNowPlayingEpisode = false
                }
            }
        }
    }
    
    func getNowPlayingEpisode() -> Episode? {
        let realm = try! Realm()
        let predicate = NSPredicate(format: "isNowPlayingEpisode == true")
        let result = realm.objects(Episode.self).filter(predicate)
        return result.first
    }
    
    
    func getFavoriteEpisodes() -> [Episode]? {
        let realm = try! Realm()
        let predicate = NSPredicate(format: "isFavorite == true")
        let results = Array(realm.objects(Episode.self).filter(predicate))
        return results
    }
    
    func markEpisodeAsFavorite(episode: Episode) {
        let realm = try! Realm()
        try! realm.write {
            episode.isFavorite = true
        }
    }
    
    func markEpisodeAsNotFavoirte(episode: Episode) {
        let realm = try! Realm()
        try! realm.write {
            episode.isFavorite = false
        }
    }
    
    
    func getFormattedLastUpdatedDateForPodcast(podcast:Podcast) -> String {
        let result = fetchEpisodesForPodcast(podcast: podcast)
        
        if let date = result.first?.publishedDate {
            
            let realm = try! Realm()
            try! realm.write {
                podcast.lastUpdated = date
            }
            
            let calendar = NSCalendar.current
            
            let date1 = calendar.startOfDay(for: date)
            let date2 = calendar.startOfDay(for: Date())
            
            let components = calendar.dateComponents([.day], from: date1, to: date2)
            
            switch components.day! {
            case 0:
                return "Updated Today"
            case 1:
                return "Updated Yesterday"
            case 2,3,4,5,6:
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE"
                let dateString = formatter.string(from: date)
                return "Updated " + dateString
            default:
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM d"
                let dateString = formatter.string(from: date)
                return "Updated " + dateString
            }
        }
        return "" 
    }
   
    
    
    
//    func fetchTopPodcast() -> [TopPodcast] {
//        let realm = try! Realm()
//        let allTopPodcast = Array(realm.objects(TopPodcast.self))
//        let sortedTopPodcast = allTopPodcast.sorted{$0.ranking < $1.ranking}
//        return sortedTopPodcast
//    }
    
    
    func fetchAllSearchResultPodcast() -> [Podcast] {
        print("fetching Search Results")
        let realm = try! Realm()
        let predicate = NSPredicate(format: "isSearchResult == %@", NSNumber(value: true))
        let allSubscribedPodcast = Array(realm.objects(Podcast.self).filter(predicate))
        print("done fetching search results")
        return allSubscribedPodcast
    }
    
    func fetchAllSubscribedPodcast() -> [Podcast] {
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "isSubscribed == %@", NSNumber(value: true))
        let allSubscribedPodcast = Array(realm.objects(Podcast.self).filter(predicate))
        for podcast in allSubscribedPodcast {
            let _ = getFormattedLastUpdatedDateForPodcast(podcast: podcast)
        }

        let sortedSubscribedPodcast = allSubscribedPodcast.sorted{$0.lastUpdated! > $1.lastUpdated!}
        return sortedSubscribedPodcast
    }
    
    func setPodcastToSubscribed(podcast: Podcast) {
        let realm = try! Realm()
        try! realm.write {
            podcast.isSearchResult = false
            podcast.isSubscribed = true
        }
    }
    
    func setEpisodeCurrentPlaybackDuration(episode: Episode, currentPlaybackDuration: Double) {
        let realm = try! Realm()
        try! realm.write {
            episode.currentPlaybackDuration = currentPlaybackDuration
        }
        let timeRemaining = episode.estimatedDuration - currentPlaybackDuration
        if timeRemaining < 45 {
            setEpisodeToPlayed(episode: episode)
        }
        
    }
    
    func setEpisodeToPlayed(episode: Episode) {
        let realm = try! Realm()
        try! realm.write {
            episode.isPlayed = true
        }
    }
    
    func setEpisodeDuration(episode: Episode, duration: Double) {
        let realm = try! Realm()
        try! realm.write {
            episode.duration = duration
        }
    }
    
    func setPodcastToSearchResult(id: String) {
        let realm = try! Realm()
        let predicate = NSPredicate(format: "iD == %@", id)
        let results = Array(realm.objects(Podcast.self).filter(predicate))
        if results.count > 0 {
            let podcast = results.first
            try! realm.write {
                podcast?.isSearchResult = true
            }
        }
        DispatchQueue.main.async {
//            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "podcastArtworkDownloaded"), object: nil)
        }
        
        
    }
    
    func deletePodcast(podcast: Podcast) {
        let episodes = fetchEpisodesForPodcast(podcast: podcast)
        let realm = try! Realm()
        try! realm.write {
            realm.delete(podcast)
            realm.delete(episodes)
        }
    }
    
    func deleteNewestEpisodeForPodcast(podcast: Podcast) {
        let episodes = fetchEpisodesForPodcast(podcast: podcast)
        let realm = try! Realm()
        try! realm.write {
            realm.delete(episodes.first!)
        }
    }
    
    
    func deleteUnsubscribedPodcast() {
        let realm = try! Realm()
        let predicate = NSPredicate(format: "isSubscribed == %@", NSNumber(value: false))
        var allUnsubscribedPodcast = Array(realm.objects(Podcast.self).filter(predicate))
        if allUnsubscribedPodcast.count > 0 {
            for podcast in allUnsubscribedPodcast {
                if podcast.isSubscribed {
                    allUnsubscribedPodcast.remove(at: allUnsubscribedPodcast.index(of: podcast)!)
                    try! realm.write {
                        podcast.isSearchResult = false
                    }
                }
            }
            
        try! realm.write {
            for podcastToDelete in allUnsubscribedPodcast {
                let episodes = fetchEpisodesForPodcast(podcast: podcastToDelete)
                realm.delete(episodes)
            }
            realm.delete(allUnsubscribedPodcast)
            }
        }
        

    }
    
    func markEpisodeAsDownloaded(episode: Episode) {
        let realm = try! Realm()
        try! realm.write {
            episode.isDownloaded = true
        }
        
    }

    func markEpisodeAsNotDownloaded(episode: Episode) {
        let realm = try! Realm()
        try! realm.write {
            episode.isDownloaded = false 
        }
    }
    
    func markEpisodesForPodcastAsNotDownloaded(podcast: Podcast) {
        let episodes = fetchEpisodesForPodcast(podcast: podcast)
        let realm = try! Realm()

        for episode in episodes {
            try! realm.write {
                episode.isDownloaded = false
            }
        }
    }
    

    
    func fetchEpisodesForPodcast(podcast:Podcast) -> [Episode] {
//        print("fetchEpisodesForPodcast - ⚡️: \(Thread.current)" + "🏭: \(OperationQueue.current?.underlyingQueue?.label ?? "None")")
        let realm = try! Realm()

        if podcast.isInvalidated {
            return [Episode]()
        }
        realm.refresh()
        let predicate = NSPredicate(format: "podcastID == %@", podcast.iD)
        let results = Array(realm.objects(Episode.self).filter(predicate).sorted(byKeyPath: "publishedDate", ascending: false))
        return results
    }
    

    
    
    
//    func addEpisodeAudioToEpisode(episode: Episode, audio: [Data]){
//        let realm = try! Realm()
//        try! realm.write {
//            for chunk in audio {
//                let episodeData = EpisodeData()
//                episodeData.soundData = chunk
//                episode.soundDataList.append(episodeData)
//            }
//        }
//        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "episodeDownloadComplete"), object: nil)
//
//    }
//

    
    
//    func deleteEpisodeDataForEpisode(episode: Episode) {
//        let realm = try! Realm()
//        try! realm.write {
//            episode.soundDataList.removeAll()
//        }
//    }
    
    func fetchLatestEpisodes() -> [Episode]? {
        let realm = try! Realm()
        let latestEpisodes = realm.objects(Episode.self).sorted(byKeyPath: "publishedDate", ascending: false)
        return Array(latestEpisodes)
    }
    
    func fetchLatestDownloadedEpiosdes() -> [Episode]? {
        let realm = try! Realm()
        let predicate = NSPredicate(format: "isDownloaded == true")
        let latestEpisodes = realm.objects(Episode.self).filter(predicate).sorted(byKeyPath: "publishedDate", ascending: false)
        return Array(latestEpisodes)
    }
    
    func fetchLatestEpisodesNumberOfEpisodesGroupedIntoDates(numberOfEpsiosdes: Int) -> [Date : [Episode]]? {
        let realm = try! Realm()
        let latestEpisodes = realm.objects(Episode.self).sorted(byKeyPath: "publishedDate", ascending: false)
        let trimmedLatestEpisodes = Array(Array(latestEpisodes).prefix(numberOfEpsiosdes))
        var dictionary = [Date : [Episode]]()
        for episode in trimmedLatestEpisodes {
            let calendar = Calendar.current
            let componets = calendar.dateComponents([.year,.month,.day], from: episode.publishedDate!)
            let date = calendar.date(from: componets)!
            if dictionary.keys.contains(date) {
                dictionary[date]?.append(episode)
            }
            else {
                dictionary[date] = [episode]
            }
        }
        
        _ = dictionary.keys.sorted(by: { $0.compare($1) == .orderedDescending })
        
        return dictionary
        
    }
    
    func fetchPodcast(withID iD: String) -> Podcast? {
        let realm = try! Realm()
        let predicate = NSPredicate(format: "iD = %@",iD)
        let podcast = realm.objects(Podcast.self).filter(predicate).first
//        _ = podcast.episodesList.sorted{$0.publishedDate! > $1.publishedDate!}
        return podcast
    }
    
    
    
    func fetchEpisodes(withIDs guids: [String]) -> [Episode] {
        let realm = try! Realm()
        var objectsToReturn = [Episode]()
        for guid in guids {
            let predicate = NSPredicate(format: "guid = %@",guid)
            let episode = realm.objects(Episode.self).filter(predicate)
            objectsToReturn.append(episode.first!)
        }
        return objectsToReturn
    }
    
    
    
    func prepareRealmToTransferEpisodes(episodes: [Episode]) -> URL {
        var config = Realm.Configuration()
        
        let intermediatePath = config.fileURL!.deletingLastPathComponent().appendingPathComponent("IntermediateTransferRealm.realm")
        let transferPath = config.fileURL!.deletingLastPathComponent().appendingPathComponent("TransferRealm.realm")
        
        if FileManager.default.fileExists(atPath: intermediatePath.path){
            try! FileManager.default.removeItem(at: intermediatePath)
        }
        
        if FileManager.default.fileExists(atPath: transferPath.path){
            try! FileManager.default.removeItem(at: transferPath)
        }
        
        
        
        //create new realm
        config.fileURL = intermediatePath
        Realm.Configuration.defaultConfiguration = config
        
        
        //Add podcast to new realm
        
        let realm = try! Realm(configuration: config)
        
        for episode in episodes {
            try! realm.write {
                realm.create(Episode.self, value: episode, update: true)
            }
        }
        
        let path = transferPath
        try! realm.writeCopy(toFile: path)
        
        return path
        
    }
    
}











