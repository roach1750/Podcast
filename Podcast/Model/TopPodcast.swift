//
//  TopPodcast.swift
//  Podcast
//
//  Created by Andrew Roach on 5/6/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import UIKit
import RealmSwift

class TopPodcast: Object {

    @objc dynamic var name: String?
    @objc dynamic var artistName: String?

    @objc dynamic var artworkLink100x100: String?
    @objc dynamic var artwork100x100: Data?
    
    @objc dynamic var iD = ""
    
    @objc dynamic var ranking = 0
    
    override static func primaryKey() -> String? {
        return "iD"
    }
    
}
