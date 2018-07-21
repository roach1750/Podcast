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
    
    
}
