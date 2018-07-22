//
//  ARAudioPlayer.swift
//  StreamTest
//
//  Created by Andrew Roach on 7/21/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import UIKit
import  AVKit
import MediaPlayer

class ARAudioPlayer: NSObject {
    
    
    static let sharedInstance: ARAudioPlayer = {
        let instance = ARAudioPlayer()
        return instance
    }()
    
    var nowPlayingEpisode: Episode? {
        didSet {
            RealmInteractor().markEpisodeAsNowPlaying(episode: nowPlayingEpisode!)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "nowPlayingEpisodeSet"), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showPlayerRemote"), object: nil)
            if oldValue != nil {
                prepareToPlay(url: URL(string: nowPlayingEpisode!.downloadURL!)!)
            }
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
    
    
    
    
    var asset: AVAsset!
    var player: AVPlayer!
    var playerItem: CachingPlayerItem!
    var delegate: ARAudioPlayerDelegate!
    let fileName = "testPodcast1"
    
    var playerState: AudioPlayerState = .stopped {
        didSet {
            if oldValue != playerState && delegate != nil {
                delegate.didChangeState(_sender: self, oldState: oldValue, newState: playerState)
                print("New State is: \(playerState)")
            }
        }
    }
    
    
    
    // Key-value observing context
    private var playerItemContext = 0
    
    let requiredAssetKeys = [
        "playable",
        "hasProtectedContent"
    ]
    
    func prepareToPlay(url: URL) {
        // Create the asset to play
        playerState = .waitingForConnection
        asset = AVAsset(url: url)
        
        // Create a new AVPlayerItem with the asset and an
        // array of asset keys to be automatically loaded
        
        
        if let episodeData = FileSystemInteractor().openFileWithFileName(fileName: fileName) {
            playerItem = CachingPlayerItem(data: episodeData, mimeType:  "audio/mpeg", fileExtension: "mp3")
        }
        else {
            playerItem = CachingPlayerItem(url: url)
        }
        
        playerItem.delegate = self
        
        
        // Register as an observer of the player item's status property
        playerItem.addObserver(self,forKeyPath: #keyPath(AVPlayerItem.status),options: [.old, .new],context: &playerItemContext)
        
        // Associate the player item with the player
        player = AVPlayer(playerItem: playerItem)
        playerItem.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
        playerItem.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
        playerItem.addObserver(self, forKeyPath: "playbackBufferFull", options: .new, context: nil)
        player.automaticallyWaitsToMinimizeStalling = false
        delegate.didFindDuration(_sender: self, duration: Float(CMTimeGetSeconds(self.asset.duration)))
        setupNowPlayingInfoCenter()
    }
    
    
    override func observeValue(forKeyPath keyPath: String?,of object: Any?,change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItemStatus
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            switch status {
            case .readyToPlay:
                print("readyToPlay")
                addPeriodicTimeObserver()
                player.play()
                playerState = .playing
            case .failed:
                print("failed")
            case .unknown:
                print("unknown")
            }
        }
            
        else if object is AVPlayerItem {
            //            print(playerItem.loadedTimeRanges)
            switch keyPath {
            case "playbackBufferEmpty":
                //                print("buffering")
                playerState = .buffering
                //            case "playbackLikelyToKeepUp":
                //                print("likely to keep up")
                //            case "playbackBufferFull":
            //                print("playbackBuffer Full")
            default:
                break
            }
        }
    }
    
    func changePausePlay() {
        if player != nil {
            if(player.timeControlStatus == AVPlayerTimeControlStatus.paused)
            {
                player.play()
                playerState = .playing
            }
            else if(player.timeControlStatus==AVPlayerTimeControlStatus.playing)
            {
                player.pause()
                playerState = .paused
            }
        }
        else {
            prepareToPlay(url: URL(string: nowPlayingEpisode!.downloadURL!)!)
        }
    }
    
    fileprivate let seekDuration: Float64 = 15
    
    func skipForward() {
        guard let duration  = player.currentItem?.duration else{
            return
        }
        let playerCurrentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = playerCurrentTime + seekDuration
        
        if newTime < CMTimeGetSeconds(duration) {
            
            let time2: CMTime = CMTimeMake(Int64(newTime * 1000 as Float64), 1000)
            player.seek(to: time2)
        }
    }
    
    func skipBackward() {
        let playerCurrentTime = CMTimeGetSeconds(player.currentTime())
        var newTime = playerCurrentTime - seekDuration
        
        if newTime < 0 {
            newTime = 0
        }
        let time2: CMTime = CMTimeMake(Int64(newTime * 1000 as Float64), 1000)
        player.seek(to: time2)
    }
    
    func seekToDuration(duration: Double) {
        player.seek(to:CMTimeMake(Int64(duration), 1))
        
    }
    
    var timeObserverToken: Any?
    
    func addPeriodicTimeObserver() {
        // Notify every half second
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 0.5, preferredTimescale: timeScale)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] time in
            self?.delegate.progressUpdated(_sender: self!, timeUpdated: Float(CMTimeGetSeconds(time)))
        }
    }
    
    func removePeriodicTimeObserver() {
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
}

//Info Center
extension ARAudioPlayer {
    func setupNowPlayingInfoCenter() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        MPRemoteCommandCenter.shared().playCommand.isEnabled = true
        MPRemoteCommandCenter.shared().playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.changePausePlay()
            //            self.updateNowPlayingInfoCenter()
            return .success
        }
        
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.changePausePlay()
            //            self.updateNowPlayingInfoCenter()
            return .success
        }
        
        MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = true
        MPRemoteCommandCenter.shared().skipForwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.skipForward()
            return .success
        }
        
        MPRemoteCommandCenter.shared().skipBackwardCommand.isEnabled = true
        MPRemoteCommandCenter.shared().skipBackwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.skipBackward()
            return .success
        }
        
    }
    
    func updateNowPlayingInfoCenter() {
        
    }
}


extension ARAudioPlayer: CachingPlayerItemDelegate {
    
    func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data) {
        print("Finished Download")
        //Now write file to disk:
        
    }
    
    func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int){
    }
    
    func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error) {
        print("Download failed with error: \(error)")
    }
    
}


















