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
import KDEAudioPlayer


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
            ARAudioPlayer.sharedInstance.nowPlayingEpisode = RealmInteractor().getNowPlayingEpisode()
            ARAudioPlayer.sharedInstance.nowPlayingPodcast = ARAudioPlayer.sharedInstance.nowPlayingEpisode?.podcast
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(SmallPlayerRemoteVC.nowPlayingEpisodeSet), name: NSNotification.Name(rawValue: "nowPlayingEpisodeSet"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SmallPlayerRemoteVC.configureArtwork), name: NSNotification.Name(rawValue: "podcastArtworkDownloaded"), object: nil)
        ARAudioPlayer.sharedInstance.delegate = self
        configurePlayPauseButton()
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
        if ARAudioPlayer.sharedInstance.nowPlayingPodcast?.artwork100x100 != nil {
            podcastImageView.image = UIImage(data: (ARAudioPlayer.sharedInstance.nowPlayingPodcast?.artwork100x100)!)
        }
    }
    
    func configurePlayPauseButton() {
        
        if ARAudioPlayer.sharedInstance.playerState == .playing {
            self.playPauseButton.setImage(UIImage(named: "Pause Button"), for: .normal)
        }
        else {
            self.playPauseButton.setImage(UIImage(named: "Play Button"), for: .normal)
        }
    }
    
    func setUpactivityView() {
        //small
        if activityView != nil {
            activityView?.startAnimating()
            activityView?.isHidden = false
        }
        else{
            let smallImageWidth = podcastImageView.bounds.size.width
            let smallImageHeight = podcastImageView.bounds.size.height
            let frame = CGRect(x: smallImageWidth/4, y: smallImageHeight/4, width: smallImageWidth / 2, height: smallImageHeight / 2)
            activityView = NVActivityIndicatorView(frame: frame, type: .lineScalePulseOut, color: .white, padding: nil)
            activityView?.startAnimating()
            view.addSubview(activityView!)
        }
    }
}


extension SmallPlayerRemoteVC: ARAudioPlayerDelegate {



    func progressUpdated(_sender: ARAudioPlayer, timeUpdated: Float) {
        
    }

    func didChangeState(_sender: ARAudioPlayer, oldState: AudioPlayerState, newState: AudioPlayerState) {

        print("Old State: \(oldState) New State: \(newState)")
        configurePlayPauseButton()

        switch newState {
        case .playing:
            if self.activityView != nil && self.activityView?.isHidden == false {
                self.activityView?.stopAnimating()
                self.activityView?.isHidden = true
            }
        case .buffering:
            setUpactivityView()
        case .stopped:
            //reached the end of the episode:
            RealmInteractor().setEpisodeToPlayed(episode: ARAudioPlayer.sharedInstance.nowPlayingEpisode!)
        default:
            return
        }
    }
    
    func didFindDuration(_sender: ARAudioPlayer, duration: Float) {
        print("did find duration of: \(duration)")
        let episode = ARAudioPlayer.sharedInstance.nowPlayingEpisode
        if episode?.duration == 0 {
            RealmInteractor().setEpisodeDuration(episode: episode!, duration: Double(duration))
        }
    }
}


