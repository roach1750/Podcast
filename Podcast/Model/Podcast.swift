//
//  Podcast.swift
//  Podcast
//
//  Created by Andrew Roach on 10/15/17.
//  Copyright © 2017 Andrew Roach. All rights reserved.
//

import UIKit
import RealmSwift
class Podcast: Object {

//    var episodesList = List<Episode>()
    @objc dynamic var name: String?
    @objc dynamic var artworkLink100x100: String?
    @objc dynamic var artwork100x100: Data?
    @objc dynamic var artworkLink600x600: String?
    @objc dynamic var artwork600x600: Data?
    
    
    @objc dynamic var iD = ""
    @objc dynamic var descript: String?
    @objc dynamic var isSubscribed = false
    @objc dynamic var isSearchResult = false
    @objc dynamic var havePlayedEpisode = false

    @objc dynamic var downloadLink: String?
    @objc dynamic var lastUpdated: Date?
    @objc dynamic var ranking = 0

    override static func primaryKey() -> String? {
        return "iD"
    }

}
