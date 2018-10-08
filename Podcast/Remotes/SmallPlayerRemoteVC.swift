//
//  SmallPlayerRemoteVC.swift
//  Podcast
//
//  Created by Andrew Roach on 7/12/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import RealmSwift
import NVActivityIndicatorView


class SmallPlayerRemoteVC: UIViewController {

    @IBOutlet var podcastImageView: UIImageView!
    @IBOutlet var episodeTitleLabel: UILabel!
    @IBOutlet var playPauseButton: UIButton!
    @IBOutlet var skipForwardButton: UIButton!
    
    var activityView: NVActivityIndicatorView?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        let inset = CGFloat(7)
        self.playPauseButton.imageEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        self.skipForwardButton.imageEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        
        ARAudioPlayer.sharedInstance.delegate = self

        if ARAudioPlayer.sharedInstance.nowPlayingEpisode == nil {
            if let previouslyPlayingEpisode = RealmInteractor().getNowPlayingEpisode() {
                ARAudioPlayer.sharedInstance.nowPlayingEpisode = previouslyPlayingEpisode
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(SmallPlayerRemoteVC.nowPlayingEpisodeSet), name: NSNotification.Name(rawValue: "nowPlayingEpisodeSet"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SmallPlayerRemoteVC.configureArtwork), name: NSNotification.Name(rawValue: "podcastArtworkDownloaded"), object: nil)
        ARAudioPlayer.sharedInstance.delegate = self
        configurePlayPauseButton()
        setUpactivityView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ARAudioPlayer.sharedInstance.delegate = nil 
    }

    
    @IBAction func playPauseButtonPressed(_ sender: UIButton) {
        ARAudioPlayer.sharedInstance.changePausePlay()
    }
    
    @IBAction func skipForwardButtonPressed(_ sender: UIButton) {
        ARAudioPlayer.sharedInstance.skipForward()
    }
    
    func nowPlayingEpisodeSet() {
        episodeTitleLabel.text = ARAudioPlayer.sharedInstance.nowPlayingEpisode?.title!
        configureArtwork()
    }
    
    func configureArtwork() {
        print("configure artwork")
        if ARAudioPlayer.sharedInstance.nowPlayingPodcast?.artwork100x100 != nil {
            podcastImageView.image = UIImage(data: (ARAudioPlayer.sharedInstance.nowPlayingPodcast?.artwork100x100)!)
        }
    }
    
    func configurePlayPauseButton() {
        DispatchQueue.main.async {

        if ARAudioPlayer.sharedInstance.playerState == .playing {
            self.playPauseButton.setImage(UIImage(named: "Pause Button"), for: .normal)
        }
        else {
            self.playPauseButton.setImage(UIImage(named: "Play Button"), for: .normal)
        }
        }
    }
    
    func setUpactivityView(callingFunctionName: String = #function) {
        
//        print("Calling Function: \(callingFunctionName)")

        
        DispatchQueue.main.async {
            print(ARAudioPlayer.sharedInstance.playerState)
            if ARAudioPlayer.sharedInstance.playerState == .playing || ARAudioPlayer.sharedInstance.playerState == .paused || ARAudioPlayer.sharedInstance.playerState == .stopped {
                self.activityView?.removeFromSuperview()
                return
            }
            else {
            if self.activityView != nil {
                self.activityView?.startAnimating()
                self.view.addSubview(self.activityView!)
                print("adding small activity view reuse")

            }
            else {
                let smallImageWidth = self.podcastImageView.bounds.size.width
                let smallImageHeight = self.podcastImageView.bounds.size.height
                let frame = CGRect(x: smallImageWidth/4, y: smallImageHeight/4, width: smallImageWidth / 2, height: smallImageHeight / 2)
                self.activityView = NVActivityIndicatorView(frame: frame, type: .lineScalePulseOut, color: .white, padding: nil)
                self.activityView?.startAnimating()
                self.view.addSubview(self.activityView!)
                print("adding small activity view initial")

                }
            }
        }
    }
    

}


extension SmallPlayerRemoteVC: ARAudioPlayerDelegate {



    func progressUpdated(timeUpdated: Float) {
        let episode = ARAudioPlayer.sharedInstance.nowPlayingEpisode
        let currentTime = Double(timeUpdated)
        RealmInteractor().setEpisodeCurrentPlaybackDuration(episode: episode!, currentPlaybackDuration: Double(currentTime))
    }

    func didChangeState(oldState: AudioPlayerState, newState: AudioPlayerState) {

        print("Old State: \(oldState) New State: \(newState)")
        configurePlayPauseButton()
        
        switch newState {
        case .playing:
            self.activityView?.removeFromSuperview()
        case .paused:
            self.activityView?.removeFromSuperview()

        case .waitingForConnection:
            setUpactivityView()
        case .buffering:
            setUpactivityView()
        case .stopped:
            //reached the end of the episode:
            RealmInteractor().setEpisodeToPlayed(episode: ARAudioPlayer.sharedInstance.nowPlayingEpisode!)
        default:
            return
        }
    }
    
    func didFindDuration(duration: Float) {
        print("did find duration of: \(duration)")
        DispatchQueue.main.async {
            let episode = ARAudioPlayer.sharedInstance.nowPlayingEpisode
            if episode?.duration == 0 {
                RealmInteractor().setEpisodeDuration(episode: episode!, duration: Double(duration))
            }
        }
    }
}

extension Thread {
    class func printCurrent() {
        print("\r⚡️: \(Thread.current)\r" + "🏭: \(OperationQueue.current?.underlyingQueue?.label ?? "None")\r")
    }
}

