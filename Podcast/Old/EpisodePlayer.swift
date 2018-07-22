////
////  ARAudioPlayer.swift
////  Podcast
////
////  Created by Andrew Roach on 10/12/17.
////  Copyright © 2017 Andrew Roach. All rights reserved.
////
//
//import UIKit
//import AVFoundation
//import MediaPlayer
//import RealmSwift
//class EpisodePlayer: NSObject {
//    
//    static let sharedInstance: EpisodePlayer = {
//        let instance = EpisodePlayer()
//        return instance
//    }()
//
//    var audioPlayer = AVPlayer()
//
//    var isPlaying: Bool {
//        return audioPlayer.rate != 0 && audioPlayer.error == nil
//    }
//    
//    fileprivate let seekDuration: Float64 = 15
//
//    
//    var nowPlayingEpisode: Episode? {
//        willSet {
//            if nowPlayingEpisode != nil {
//                print("previous episode is: \(nowPlayingEpisode!.title!), duration is: \(CMTimeGetSeconds((audioPlayer.currentItem?.duration)!)) current time is: \(CMTimeGetSeconds(audioPlayer.currentTime())) ")
//                RealmInteractor().setEpisodeCurrentPlaybackDuration(episode: nowPlayingEpisode!, currentPlaybackDuration: floor(CMTimeGetSeconds(audioPlayer.currentTime())))
//            }
//        }
//    }
//    var nowPlayingPodcast: Podcast?
//    
//    func initalizeViewAndHadleEpisode(episode: Episode) {
//        if episode != nowPlayingEpisode {
//            nowPlayingEpisode = episode
//            playEpisodeFromStream(episode: episode)
//        }
//    }
//    
//    func playEpisodeFromStream(episode: Episode) {
//        let asset = AVURLAsset(url: URL(string:episode.downloadURL!)!)
//        let item = AVPlayerItem(asset:asset)
////        item.preferredForwardBufferDuration = TimeInterval(Int(5))
//        audioPlayer = AVPlayer(playerItem: item)
//        setupNowPlayingInfoCenter()
//        audioPlayer.play()
////        let time = CMTimeMakeWithSeconds(episode.duration, audioPlayer.currentTime().timescale)
////        audioPlayer.seek(to: time, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
//    }
//    
//    func playEpisodeFromData(episode: Episode) {
////        let data = processDataForPlayback(episodeDataList: episode.soundDataList)
////        self.audioPlayer = try! AVAudioPlayer(data: data)
////        setupNowPlayingInfoCenter()
////        audioPlayer.prepareToPlay()
////        audioPlayer.play()
////        nowPlayingEpisode = episode
//    }
//    
//    
//    
//    
//    func processDataForPlayback(episodeDataList: List<EpisodeData>) -> Data {
//        var data = Data()
//        for episodeData in episodeDataList {
//            data.append(episodeData.soundData!)
//        }
//        return data
//    }
//
//    
//    func setupNowPlayingInfoCenter() {
//        UIApplication.shared.beginReceivingRemoteControlEvents()
//        MPRemoteCommandCenter.shared().playCommand.isEnabled = true
//        MPRemoteCommandCenter.shared().playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
//            self.audioPlayer.play()
//            self.updateNowPlayingInfoCenter()
//            return .success
//        }
//        
//        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
//        MPRemoteCommandCenter.shared().pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
//            self.audioPlayer.pause()
//            self.updateNowPlayingInfoCenter()
//            return .success
//        }
//        
//        MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = true
//        MPRemoteCommandCenter.shared().skipForwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
//            self.skipForward()
//            return .success
//        }
//        
//        MPRemoteCommandCenter.shared().skipBackwardCommand.isEnabled = true
//        MPRemoteCommandCenter.shared().skipBackwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
//            self.skipBackward()
//            return .success
//        }
//        
//    }
//    
//    func skipForward() {
//        guard let duration  = audioPlayer.currentItem?.duration else{
//            return
//        }
//        let playerCurrentTime = CMTimeGetSeconds(audioPlayer.currentTime())
//        let newTime = playerCurrentTime + seekDuration
//        if newTime < (CMTimeGetSeconds(duration) - seekDuration) {
//            let time2: CMTime = CMTimeMake(Int64(newTime * 1000 as Float64), 1000)
//            audioPlayer.seek(to: time2, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
//        }
//        else {
//            //stop we are past the time
//        }
//    }
//    
//    func skipBackward() {
//        let playerCurrentTime = CMTimeGetSeconds(audioPlayer.currentTime())
//        var newTime = playerCurrentTime - seekDuration
//        if newTime < 0 {
//            newTime = 0
//        }
//        let time2: CMTime = CMTimeMake(Int64(newTime * 1000 as Float64), 1000)
//        audioPlayer.seek(to: time2, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
//    }
//    
//    func seekToSeconds(seconds: Double) {
//        let time: CMTime = CMTimeMake(Int64(seconds * 1000 as Float64), 1000)
//        audioPlayer.seek(to: time, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
//    }
//    
//    
//    func updateNowPlayingInfoCenter() {
//        
//    }
//    
//    
//}
//
