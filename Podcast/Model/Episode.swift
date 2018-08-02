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
    @objc dynamic var isDownloaded = false
    
    @objc dynamic var podcast: Podcast?
    @objc dynamic var podcastID: String?

    
    override static func primaryKey() -> String? {
        return "guid"
    }
}

    


    
    
    
    
    

