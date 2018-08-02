//
//  EpisodesVC+URLSessionDelegate.swift
//  Podcast
//
//  Created by Andrew Roach on 7/29/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import UIKit
import Foundation

extension EpisodesVC: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let sourceURL = downloadTask.originalRequest?.url else { return }
        
        let download = downloadService.activeDownloads[sourceURL]
        downloadService.activeDownloads[sourceURL] = nil

        if let destinationURL = download?.fileURL {
            let fileManager = FileManager.default
            try? fileManager.removeItem(at: destinationURL)
            do {
                try fileManager.copyItem(at: location, to: destinationURL)
            } catch let error {
                print("Could not copy file to disk: \(error.localizedDescription)")
            }
        }
        
        DispatchQueue.main.async {
            
            RealmInteractor().markEpisodeAsDownloaded(episode: (download?.episode)!)
            
            for cell in self.tableView.visibleCells as! [EpisodeTableViewCell] {
                if cell.episode?.guid == download?.episode.guid {
                    cell.downloadView.isHidden = true
                    self.tableView.beginUpdates()
                    self.tableView.reloadRows(at: [self.tableView.indexPath(for: cell)!], with: .none)
                    self.tableView.endUpdates()
                }
            }
        }
        
        
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let url = downloadTask.originalRequest?.url, let download = downloadService.activeDownloads[url]  else { return }
        download.progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        let totalSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite,
                                                  countStyle: .file)
//        print(String(format: "%.1f%% of %@", download.progress * 100, totalSize))
        
        DispatchQueue.main.async {
            for cell in self.tableView.visibleCells as! [EpisodeTableViewCell] {
                if cell.episode?.guid == download.episode.guid {
                    cell.downloadView.isHidden = false
                    cell.updateDisplay(progress: download.progress, totalSize: totalSize)
                }
            }
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                let completionHandler = appDelegate.backgroundSessionCompletionHandler {
                appDelegate.backgroundSessionCompletionHandler = nil
                completionHandler()
            }
        }
    }


}
