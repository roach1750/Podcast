//
//  SingletonPlayerDelegate.swift
//  Podcast
//
//  Created by Andrew Roach on 11/19/17.
//  Copyright © 2017 Andrew Roach. All rights reserved.
//

import UIKit
import KDEAudioPlayer
import MediaPlayer

class SingletonPlayerDelegate: AudioPlayerDelegate {
    
    static let sharedInstance: SingletonPlayerDelegate = {
        let instance = SingletonPlayerDelegate()
        return instance
    }()
    var nowPlayingEpisode: Episode? {
        didSet {
            RealmInteractor().markEpisodeAsNowPlaying(episode: nowPlayingEpisode!)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "nowPlayingEpisodeSet"), object: nil)

        }
    }
    var nowPlayingPodcast: Podcast? {
        didSet {
            if nowPlayingPodcast?.artwork100x100 == nil {
                Downloader().downloadImageForPodcast(podcast: nowPlayingPodcast!, highRes: false)
            }
            if nowPlayingPodcast?.artwork600x600 == nil {
                Downloader().downloadImageForPodcast(podcast: nowPlayingPodcast!, highRes: true)
            }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "nowPlayingPodcastSet"), object: nil)

        }
    }
    
    let player = AudioPlayer()
    var isPlaying = Bool()
    
    fileprivate let seekDuration: Float64 = 15
    
    
    func initalizeViewAndHandleEpisode(episode: Episode, startPlaying: Bool) {
        if episode != nowPlayingEpisode {
            nowPlayingEpisode = episode
            playEpisodeFromStream(episode: episode, startPlaying: startPlaying)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showPlayerRemote"), object: nil)
        }
    }
    
    func playEpisodeFromStream(episode: Episode, startPlaying: Bool) {
        let url = URL(string: episode.downloadURL!)
        let item = AudioItem(mediumQualitySoundURL: url)
        setUpRemoteCommandCenter(item: item)
        
        if episode.currentPlaybackDuration != 0 {
            player.seek(to: episode.currentPlaybackDuration)
            print("seeking to: \(episode.currentPlaybackDuration)")
        }
        if startPlaying == true {
            player.play(item: item!)
        }
    }
    
    func play() {
        if player.state == .stopped {
            playEpisodeFromStream(episode: nowPlayingEpisode!, startPlaying: true)
        }
        else {
            player.resume()
        }
        isPlaying = true
    }
    
    func pause() {
        player.pause()
        isPlaying = false
    }
    
    func stop() {
        player.stop()
    }
    
    func resume() {
        player.resume()
    }
    
    func adjustPlaybackRate(rate: Float) {
        player.rate = rate
    }
    
    func skipForward() {
        let playerCurrentTime = player.currentItemProgression
        let newTime = playerCurrentTime! + seekDuration
        player.seek(to: newTime)
    }
    
    
    
    func skipBackward() {
        let playerCurrentTime = player.currentItemProgression
        var newTime = playerCurrentTime! - seekDuration
        if newTime < 0 {
            newTime = 0
        }
        player.seek(to: newTime)
    }
    
    func seekToDuration(duration: Double) {
        player.seek(to: duration)
    }
    
    
    //Set up MPRemoteCommandCenter:
    
    
    func setUpRemoteCommandCenter(item: AudioItem?) {
        
        if let imageData = nowPlayingPodcast?.artwork100x100 {
            if let image = UIImage(data: imageData) {
                item?.artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { (size) -> UIImage in
                    return image
                })
            }
        }
        item?.artist = nowPlayingPodcast?.name
        item?.title = nowPlayingEpisode?.title
        
        let remoteCommandCenter = MPRemoteCommandCenter.shared()
        
        remoteCommandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.pause()
            return .success
        }
        
        remoteCommandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.play()
            return .success
        }
        
        remoteCommandCenter.skipForwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.skipForward()
            return .success
        }
        
        remoteCommandCenter.skipBackwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.skipBackward()
            return .success
        }
        
        remoteCommandCenter.changePlaybackPositionCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.player.seek(to:(event as! MPChangePlaybackPositionCommandEvent).positionTime)
            return .success
        }

    }
    
}
