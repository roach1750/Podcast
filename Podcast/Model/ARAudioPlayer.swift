//
//  ARAudioPlayer.swift
//  StreamTest
//
//  Created by Andrew Roach on 7/21/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import UIKit
import  AVKit

class ARAudioPlayer: NSObject {
    
    var URL: URL! {
        didSet {
            prepareToPlay(url: URL)
        }
    }
    
    static let sharedInstance: ARAudioPlayer = {
        let instance = ARAudioPlayer()
        return instance
    }()
    
    var asset: AVAsset!
    var player: AVPlayer!
    var playerItem: CachingPlayerItem!
    var delegate: ARAudioPlayerDelegate!
    let fileName = "testPodcast1"
    var playerState: AudioPlayerState = .stopped {
        didSet {
            if oldValue != playerState {
//                delegate.didChangeState(_sender: self, oldState: oldValue, newState: playerState)
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

        //playerItem = CachingPlayerItem(url: url)
        
        if let episodeData = FileSystemInteractor().openFileWithFileName(fileName: fileName) {
            playerItem = CachingPlayerItem(data: episodeData, mimeType:  "audio/mpeg", fileExtension: "mp3")
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
                print("buffering")
                playerState = .buffering
            case "playbackLikelyToKeepUp":
                print("likely to keep up")
            case "playbackBufferFull":
                print("playbackBuffer Full")
            default:
                break
            }
        }
    }
    
    func changePausePlay() {
        
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


















