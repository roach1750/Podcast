//
//  FileSystemInteractor.swift
//  StreamTest
//
//  Created by Andrew Roach on 7/21/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import UIKit

class FileSystemInteractor: NSObject {
    
    func openFileWithFileName(fileName: String) -> Data? {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(fileName)
            //reading
            do {
                let episodeData = try Data(contentsOf: fileURL)
                return episodeData
            }
            catch {/* error handling here */}
        }
        return nil 
    }
    
    func saveFileToDisk(file: Data, fileName: String) {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(fileName)
            print("Saving file to: \(fileURL)")
            //writing
            do {
                try file.write(to: fileURL)
            }
            catch {/* error handling here */}
        }
    }
    
    func deleteFile(fileName: String) {
        let filemanager = FileManager.default
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask,true)[0] as NSString
        let destinationPath = documentsPath.appendingPathComponent(fileName)
        try! filemanager.removeItem(atPath: destinationPath)
        
    }
    
    func deleteFilesFor(podcast: Podcast) {
        let filemanager = FileManager.default
        for fileURL in fetchFileURLS() {
            if fileURL.absoluteString.contains(podcast.iD) {
                try! filemanager.removeItem(at: fileURL)
            }
        }
    }
    
    func fetchFileURLS() -> [URL] {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var fileURLs = try! fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
        for fileURL in fileURLs {
            if !fileURL.absoluteString.contains("EpisodeData_") {
                fileURLs.remove(at: fileURLs.index(of: fileURL)!)
            }
        }
        return fileURLs
    }
    
    func fetchFileSizes() -> [Podcast: Int]? {
        var results = [Podcast: Int]()
        for fileURL in fetchFileURLS() {
            let podcastID = fileURL.absoluteString.components(separatedBy: "_").last
            do {
                let resources = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                let fileSize = resources.fileSize
                if let podcast = RealmInteractor().fetchPodcast(withID: podcastID!) {
                    if results[podcast] == nil {
                        results[podcast] = fileSize
                    }
                    else {
                        results[podcast]! += fileSize!
                    }
                }
            }
            catch {
                print("error")
            }
        }
        return results
    }
}
