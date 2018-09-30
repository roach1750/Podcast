//
//  WatchAudioPlayer.swift
//  WatchPodcast Extension
//
//  Created by Andrew Roach on 9/29/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import WatchKit
import AVFoundation
import MediaPlayer

class WatchAudioPlayer: NSObject {
    
    static let sharedInstance: WatchAudioPlayer = {
        let instance = WatchAudioPlayer()
        return instance
    }()
    
    var audioPlayer: AVAudioPlayer?
    
    var nowPlayingEpisode: Episode?
    
    fileprivate let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()

    func playPodcastEpisode(episode: Episode) {
        nowPlayingEpisode = episode
        try! setupAudioSession()
        
        let dirPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                           .userDomainMask, true)
        let docsDir = dirPaths[0] as String
        let filemgr = FileManager.default
        if let data = filemgr.contents(atPath: docsDir + "EpisodeData_" + (episode.guid?.replacingOccurrences(of: "/", with: ""))! + "_" + (episode.podcast?.iD)!) {
            print(data.count)
            
            AVAudioSession.sharedInstance().activate(options: []) { (bool, error) in
                if let error = error {
                    print(error)
                }
                else {
                    self.audioPlayer?.play()
                    self.configureNowPlayignInfoCenter()
                }
            }
        }
    }
    
    func setupAudioSession() throws {
        try AVAudioSession.sharedInstance().setCategory(
            AVAudioSession.Category.playback,
            mode: AVAudioSession.Mode.default,
            policy: .longForm,
            options: []
        )
    }

    func configureNowPlayignInfoCenter() {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = nowPlayingEpisode?.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = nowPlayingEpisode?.podcast?.name
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }

}

