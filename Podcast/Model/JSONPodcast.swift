//
//  Podcast.swift
//  JSON Parser
//
//  Created by Andrew Roach on 5/5/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import UIKit

enum PodcastType {
    case Top
    case SearchResults
    case Individual
}

struct iTunesPodcastResults: Codable {
    
    var resultCount: Int
    var results: [JSONPodcast]
    
    struct JSONPodcast: Codable {
        let artistId: Int?
        let collectionId: Int?
        let trackId: Int?
        let artistName: String?
        let collectionName: String?
        let trackName: String?
        let feedUrl: String?
        let artworkUrl30: String?
        let artworkUrl60: String?
        let artworkUrl100: String?
        let artworkUrl600: String?
    }
}

struct iTunesTopPodcast: Codable {
    var results: [TopPodcast]
    struct TopPodcast: Codable {
        let artistName: String?
        let id: String?
        let name: String?
        let artworkUrl100: String?
    }
}

