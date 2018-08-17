//
//  EpisodeDownloader.swift
//  Podcast
//
//  Created by Andrew Roach on 7/28/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import UIKit
import RealmSwift

class EpisodeDownloader: NSObject  {
    
    
    // SearchViewController creates downloadsSession
    var downloadsSession: URLSession!
    var activeDownloads: [URL: DownloadObject] = [:]
    
    // MARK: - Download methods called by TrackCell delegate methods
    
    func startDownload(_ episode: Episode) {
        let download = DownloadObject(episode: episode)
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let shortfileName = "EpisodeData_" + (episode.guid?.replacingOccurrences(of: "/", with: ""))! + "_" + (episode.podcast?.iD)!
            download.fileURL = dir.appendingPathComponent(shortfileName)
        }
        
        download.task = downloadsSession.downloadTask(with: URL(string: episode.downloadURL!)!)
        download.task!.resume()
        download.isDownloading = true
        activeDownloads[URL(string: episode.downloadURL!)!] = download
    }
    
    func pauseDownload(_ episode: Episode) {
        guard let download = activeDownloads[URL(string: episode.downloadURL!)!] else { return }
        if download.isDownloading {
            download.task?.cancel(byProducingResumeData: { data in
                download.resumeData = data
            })
            download.isDownloading = false
        }
    }
    
    func cancelDownload(_ episode: Episode) {
        if let download = activeDownloads[URL(string: episode.downloadURL!)!] {
            download.task?.cancel()
            activeDownloads[URL(string: episode.downloadURL!)!] = nil
        }
    }
    
    func resumeDownload(_ episode: Episode) {
        guard let download = activeDownloads[URL(string: episode.downloadURL!)!] else { return }
        if let resumeData = download.resumeData {
            download.task = downloadsSession.downloadTask(withResumeData: resumeData)
        } else {
            download.task = downloadsSession.downloadTask(with: URL(string: episode.downloadURL!)!)
        }
        download.task!.resume()
        download.isDownloading = true
    }


}
