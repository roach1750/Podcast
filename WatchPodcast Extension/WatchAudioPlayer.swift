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
    
    var nowPlayingEpisode: Episode? {
        didSet {
            print("Nowplayingepisode set on  - ⚡️: \(Thread.current)" + "🏭: \(OperationQueue.current?.underlyingQueue?.label ?? "None")")
        }
    }
    
    fileprivate let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()

    func playPodcastEpisode(episode: Episode) {
        nowPlayingEpisode = episode
        try! setupAudioSession()
        
        let dirPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                           .userDomainMask, true)
        let docsDir = dirPaths[0] as String
        let filemgr = FileManager.default
        

        
        if let data = filemgr.contents(atPath: docsDir + "/EpisodeData_" + (episode.guid?.replacingOccurrences(of: "/", with: ""))! + "_" + (episode.podcast?.iD)!) {
            
            print("Found episode File size of: \(data.count)")
            
            AVAudioSession.sharedInstance().activate(options: []) { (bool, error) in
                
                if let error = error {
                    print("Error from activating the auido session: \(error)")
                }
                else {
                    print("Telling audio player to PLAY")
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
        DispatchQueue.main.async {
            print("configureNowPlayignInfoCenter called on  - ⚡️: \(Thread.current)" + "🏭: \(OperationQueue.current?.underlyingQueue?.label ?? "None")")
            var nowPlayingInfo = [String: Any]()
            nowPlayingInfo[MPMediaItemPropertyTitle] = self.nowPlayingEpisode?.title
            nowPlayingInfo[MPMediaItemPropertyArtist] = self.nowPlayingEpisode?.podcast?.name
            self.nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        }
    }
    
    fileprivate let remoteCommandCenter = MPRemoteCommandCenter.shared()
    
//    func enableSkipForwardCommand(interval: Int = 15) {
//        remoteCommandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: interval)]
//        remoteCommandCenter.skipForwardCommand.addTarget(self, action:
//            #selector(RemoteCommandManager.
//            handleSkipForwardCommandEvent(event:)))
//        remoteCommandCenter.skipForwardCommand.isEnabled = true
//    }
//
//    func handleSkipForwardCommandEvent() {
//
//    }
    

    
    
    
    
}

