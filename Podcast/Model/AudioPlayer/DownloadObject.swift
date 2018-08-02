//
//  DownloadObject.swift
//  Podcast
//
//  Created by Andrew Roach on 7/29/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import UIKit

class DownloadObject: NSObject {
    
    var episode: Episode
    
    init(episode: Episode) {
        self.episode = episode
    }
    
    // Download service sets these values:
    var task: URLSessionDownloadTask?
    var isDownloading = false
    var resumeData: Data?
    var fileURL: URL?
    
    // Download delegate sets this value:
    var progress: Float = 0
    
}
