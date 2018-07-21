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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(SmallPlayerRemoteVC.nowPlayingEpisodeSet), name: NSNotification.Name(rawValue: "nowPlayingEpisodeSet"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SmallPlayerRemoteVC.configureArtwork), name: NSNotification.Name(rawValue: "podcastArtworkDownloaded"), object: nil)
        SingletonPlayerDelegate.sharedInstance.player.delegate = self
        configurePlayPauseButton()
    }
    

    
    @IBAction func playPauseButtonPressed(_ sender: UIButton) {
        if SingletonPlayerDelegate.sharedInstance.isPlaying {
            SingletonPlayerDelegate.sharedInstance.pause()
        }
        else {
            SingletonPlayerDelegate.sharedInstance.play()
        }
    }
    
    @IBAction func skipForwardButtonPressed(_ sender: UIButton) {
        SingletonPlayerDelegate.sharedInstance.skipForward()
    }
    
    func nowPlayingEpisodeSet() {
        episodeTitleLabel.text = SingletonPlayerDelegate.sharedInstance.nowPlayingEpisode?.title!
        configureArtwork()
    }
    
    func configureArtwork() {
        if SingletonPlayerDelegate.sharedInstance.nowPlayingPodcast?.artwork100x100 != nil {
            podcastImageView.image = UIImage(data: (SingletonPlayerDelegate.sharedInstance.nowPlayingPodcast?.artwork100x100)!)
        }
    }
    
    func configurePlayPauseButton() {
        if SingletonPlayerDelegate.sharedInstance.isPlaying == true {
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


extension SmallPlayerRemoteVC: AudioPlayerDelegate {
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didChangeStateFrom from: AudioPlayerState, to state: AudioPlayerState) {
        
        print("\nDid change state called from: \(from) to: \(state)")
        
        switch state {
        case .playing:
            if self.activityView != nil && self.activityView?.isHidden == false {
                self.activityView?.stopAnimating()
                self.activityView?.isHidden = true
            }
            SingletonPlayerDelegate.sharedInstance.isPlaying = true
        case .paused:
            DispatchQueue.main.async {}
            SingletonPlayerDelegate.sharedInstance.isPlaying = false
        case .buffering:
            setUpactivityView()
        case .stopped:
            //reached the end of the episode:
            RealmInteractor().setEpisodeToPlayed(episode: SingletonPlayerDelegate.sharedInstance.nowPlayingEpisode!)
        default:
            return
        }
        configurePlayPauseButton()
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didFindDuration duration: TimeInterval, for item: AudioItem) {
        print("did find duration of: \(duration)")
        let episode = SingletonPlayerDelegate.sharedInstance.nowPlayingEpisode
        if episode?.duration == 0 {
            RealmInteractor().setEpisodeDuration(episode: episode!, duration: duration)
        }
    }
}


