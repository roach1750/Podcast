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
            nowPlayingPodcast = nowPlayingEpisode?.podcast
            self.configureCommandCenter()
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
        if player != nil {
            removePeriodicTimeObserver()
        }
        
        // Create the asset to play
        playerState = .waitingForConnection
        asset = AVAsset(url: url)
        
        // Create a new AVPlayerItem with the asset and an
        // array of asset keys to be automatically loaded
        
        
//        if let episodeData = FileSystemInteractor().openFileWithFileName(fileName: fileName) {
//            playerItem = CachingPlayerItem(data: episodeData, mimeType:  "audio/mpeg", fileExtension: "mp3")
//        }
//        else {
            playerItem = CachingPlayerItem(url: url)
//        }
        
        
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
                addPeriodicTimeObserver()
                player.play()
                print("starting to play")
                playerState = .playing
            case .failed:
                print("failed")
            case .unknown:
                print("unknown")
            }
        }
            
        else if object is AVPlayerItem {
            switch keyPath {
            case "playbackBufferEmpty":
                playerState = .buffering
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
        self.updateNowPlayingInfoForCurrentPlaybackItem()
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
            print(CMTimeGetSeconds(time))
        }
    }
    
    func removePeriodicTimeObserver() {
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }


//Info Center
    
    let commandCenter = MPRemoteCommandCenter.shared()
    
    func configureCommandCenter() {
        self.commandCenter.playCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.player.play()
            sself.playerState = .playing
            return .success
        })
        
        self.commandCenter.pauseCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.player.pause()
            sself.playerState = .paused
            return .success
        })
        
        self.commandCenter.skipForwardCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.skipForward()
            return .success
        })
        
        self.commandCenter.skipBackwardCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.skipBackward()
            return .success
        })
        
    }
    
    //MARK: - Now Playing Info
    
    var nowPlayingInfo: [String : AnyObject]?

    
    func updateNowPlayingInfoForCurrentPlaybackItem() {
        guard let currentPlaybackItem = self.nowPlayingEpisode, let currentPlaybackPodcast = self.nowPlayingPodcast else {
            self.configureNowPlayingInfo(nil)
            return
        }
        
        var nowPlayingInfo = [MPMediaItemPropertyTitle: currentPlaybackItem.title!,
                              MPMediaItemPropertyArtist: currentPlaybackPodcast.name!,
//                              MPMediaItemPropertyPlaybackDuration: playerItem.duration,
                              MPNowPlayingInfoPropertyPlaybackRate: NSNumber(value: 1.0 as Float)] as [String : Any]
        
        let artworkData = nowPlayingPodcast!.artwork100x100
        let image = UIImage(data: artworkData!) ?? UIImage()
        let artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: {  (_) -> UIImage in
            return image
        })
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork

        
        self.configureNowPlayingInfo(nowPlayingInfo as [String : AnyObject]?)
        
        self.updateNowPlayingInfoElapsedTime()
    }
    
    func updateNowPlayingInfoElapsedTime() {
//        guard var nowPlayingInfo = self.nowPlayingInfo else { return }
//
//
//        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: Float(CMTimeGetSeconds(player.currentTime())))
//
//        self.configureNowPlayingInfo(nowPlayingInfo)
    }
    
    func configureNowPlayingInfo(_ nowPlayingInfo: [String: AnyObject]?) {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        self.nowPlayingInfo = nowPlayingInfo
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


















