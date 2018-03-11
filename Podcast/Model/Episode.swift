//
//  JunkiesPodcast.swift
//  Podcast
//
//  Created by Andrew Roach on 8/9/17.
//  Copyright © 2017 Andrew Roach. All rights reserved.
//

import UIKit
import RealmSwift

class Episode: Object {

    @objc dynamic var guid: String?
    @objc dynamic var title: String?
    @objc dynamic var descript: String?
    @objc dynamic var publishedDate: Date?
    @objc dynamic var estimatedDuration = 0.0
    @objc dynamic var duration = 0.0

    
    @objc dynamic var isNowPlayingEpisode = false
    @objc dynamic var isFavorite = false

    
    @objc dynamic var currentPlaybackDuration = 0.0

    @objc dynamic var downloadURL: String?
    @objc dynamic var fileSize = 0.0
    
    @objc dynamic var segmentNumber = 0
    var soundDataList = List<EpisodeData>()
    @objc dynamic var isPlayed = false
    @objc dynamic var isdownloadInProgress = false
    @objc dynamic var downloadProgress = 0.0
    
    @objc dynamic var podcast: Podcast?
    
    
    override static func primaryKey() -> String? {
        return "guid"
    }
    
//    init(guid: String?, title: String?, descript: String?, publishedDate: Date?, duration: Double, downloadURL: String?, fileSize: Double, segmentNumber: Int , soundData: Data?, isPlayed:Bool ) {
//
//        self.guid = guid
//        self.title = title
//        self.descript = descript
//        self.publishedDate = publishedDate
//        self.duration = duration
//        self.downloadURL = downloadURL
//        self.fileSize = fileSize
//        self.segmentNumber = segmentNumber
//        self.soundData = soundData
//        self.isPlayed = isPlayed
//
//    }
    


    
    
    
    
    
}
