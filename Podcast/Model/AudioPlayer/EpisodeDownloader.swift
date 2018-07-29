//
//  EpisodeDownloader.swift
//  Podcast
//
//  Created by Andrew Roach on 7/28/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import UIKit
import RealmSwift

class EpisodeDownloader: NSObject {
    
    let defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?
    
    func downloadEpisode(episode: Episode) {
        
        dataTask?.cancel()
        
        guard let url = URL(string: episode.downloadURL!) else { return }
        
        let episodeTreadSafeReference = ThreadSafeReference(to: episode)

        
        dataTask = defaultSession.dataTask(with: url) { data, response, error in
            
            
            let realm = try! Realm()
            guard let episode = realm.resolve(episodeTreadSafeReference) else {
                return
            }
            
            let fileName = "EpisodeData_" + (episode.guid?.replacingOccurrences(of: "/", with: ""))! + "_" + (episode.podcast?.iD)!
            FileSystemInteractor().saveFileToDisk(file: data!, fileName: fileName)
        }
        
        dataTask?.resume()
    }
    
    
}
