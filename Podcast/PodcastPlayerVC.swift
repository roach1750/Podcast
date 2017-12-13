//
//  PodcastPlayerViewController.swift
//  Podcast
//
//  Created by Andrew Roach on 10/9/17.
//  Copyright © 2017 Andrew Roach. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import RealmSwift
import NVActivityIndicatorView
import KDEAudioPlayer

class PodcastPlayerVC: UIViewController {
    
    var episode: Episode? {
        didSet{
            print("episode set")
            if SingletonPlayerDelegate.sharedInstance.player.state == .buffering {
                setUpActivityView()
            }
        }
    }
    
    
    @IBOutlet weak var seekSlider: UISlider!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    
    @IBOutlet weak var podcastImageView: UIImageView!
    
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var volumeView: UIView!
    @IBOutlet weak var routeButtonView: UIView!
    
    @IBOutlet weak var playBackSpeedButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    

    var activityView: NVActivityIndicatorView?
    
    
    override func viewDidLoad() {
        setUpVolumeView()
        setUpRouteButtonView()
        SingletonPlayerDelegate.sharedInstance.player.delegate = self
        print("playerViewDidLoad")
        super.viewDidLoad()
    }
    
    func reloadImage() {
        if let imageData = SingletonPlayerDelegate.sharedInstance.nowPlayingPodcast?.artwork600x600  {
            podcastImageView.image = UIImage(data: imageData)
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        print("playerViewWillAppear")

        if episode != SingletonPlayerDelegate.sharedInstance.nowPlayingEpisode {
            episode = SingletonPlayerDelegate.sharedInstance.nowPlayingEpisode
        }
        self.titleLabel.text = episode?.title
        setUpLabelsForAudioPlayer()
        UIApplication.shared.statusBarStyle = .lightContent
        if SingletonPlayerDelegate.sharedInstance.nowPlayingPodcast?.artwork600x600 != nil {
            podcastImageView.image = UIImage(data: (SingletonPlayerDelegate.sharedInstance.nowPlayingPodcast?.artwork600x600)!)
        }
        else {
//            NotificationCenter.default.addObserver(self, selector: #selector(PodcastPlayerVC.reloadImage), name: NSNotification.Name(rawValue: "podcastArtworkDownloaded"), object: nil)
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default
    }
    
    func setUpActivityView() {
        if activityView != nil {
            activityView?.startAnimating()
            activityView?.isHidden = false
        }
        else{
        let frame = CGRect(x: view.frame.width/2 - 50, y: view.frame.height/2 - 50, width: 100, height: 100)
        activityView = NVActivityIndicatorView(frame: frame, type: .lineScalePulseOut, color: .red, padding: nil)
        activityView?.startAnimating()
        view.addSubview(activityView!)
        }
        
    }
    
    
    func setUpVolumeView() {
        volumeView.backgroundColor = UIColor.clear
        let myVolumeView = MPVolumeView(frame: volumeView.bounds)
        myVolumeView.showsRouteButton = false

        volumeView.addSubview(myVolumeView)
    }
    
    func setUpRouteButtonView() {
        routeButtonView.backgroundColor = UIColor.clear
        let routeView = MPVolumeView(frame: routeButtonView.bounds)
        routeView.showsVolumeSlider = false
        routeView.tintColor = UIColor.black
//        routeView.setRouteButtonImage(UIImage(named: "AirplayButton"), for: .normal)
        routeButtonView.addSubview(routeView)
    }
    

    
    @IBAction func playBackSpeedButtonPressed(_ sender: UIButton) {
        if sender.titleLabel?.text == "1x" {
            playBackSpeedButton.setTitle("2x", for: .normal)
            SingletonPlayerDelegate.sharedInstance.adjustPlaybackRate(rate: 2.0)
        }
        else if sender.titleLabel?.text == "2x" {
            playBackSpeedButton.setTitle("3x", for: .normal)
            SingletonPlayerDelegate.sharedInstance.adjustPlaybackRate(rate: 3.0)
        }
        else if sender.titleLabel?.text == "3x" {
            playBackSpeedButton.setTitle("1/2x", for: .normal)
            SingletonPlayerDelegate.sharedInstance.adjustPlaybackRate(rate: 0.5)
        }
        else if sender.titleLabel?.text == "1/2x" {
            playBackSpeedButton.setTitle("1x", for: .normal)
            SingletonPlayerDelegate.sharedInstance.adjustPlaybackRate(rate: 1.0)
        }
    }
    
    @IBAction func settingsButtonPressed(_ sender: UIButton) {
        
        
    }
    
    @IBAction func seekSliderAdjusted(_ sender: UISlider) {
        SingletonPlayerDelegate.sharedInstance.player.seek(to: TimeInterval(sender.value))
    }
        
    
    func setUpLabelsForAudioPlayer() {

        if episode?.duration != 0 && episode?.currentPlaybackDuration != 0 {
            let currentTime = episode?.currentPlaybackDuration
            if let duration  = episode?.duration {
                seekSlider.maximumValue = Float(duration)
                let timeRemaining = duration - currentTime!
            self.adjustTimeLabel(label: self.currentTimeLabel, duration: Int(currentTime!))
            self.adjustTimeLabel(label: self.timeRemainingLabel, duration: Int(timeRemaining))
            self.seekSlider.setValue(Float(currentTime!), animated: false)
            SingletonPlayerDelegate.sharedInstance.player.seek(to: (episode?.currentPlaybackDuration)!)
            }
        }
        else {
            adjustTimeLabel(label: currentTimeLabel, duration: 0)
            adjustTimeLabel(label: timeRemainingLabel, duration: 0)
            seekSlider.setValue(0.0, animated: false)
        }
    }
    
    func adjustTimeLabel(label:UILabel, duration: Int) {
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: duration)
        if h == 0 {
            if s < 10 {
                label.text = String(m) + ":" + "0" + String(s)
            }
            else {
                label.text = String(m) + ":" + String(s)
            }
        }
        else {
            label.text = ""
        }
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
    
    @IBAction func skipBackwardButtonPressed(_ sender: UIButton) {
        SingletonPlayerDelegate.sharedInstance.skipBackward()

    }
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    
    
}

extension PodcastPlayerVC: AudioPlayerDelegate {
    func audioPlayer(_ audioPlayer: AudioPlayer, didChangeStateFrom from: AudioPlayerState, to state: AudioPlayerState) {
        print("did change state called from: \(from) to: \(state)")
        switch state {
        case .playing:
            if self.activityView != nil && self.activityView?.isHidden == false {
                self.activityView?.stopAnimating()
                self.activityView?.isHidden = true
            }
            playPauseButton.setImage(UIImage(named: "Pause Button"), for: .normal)
            SingletonPlayerDelegate.sharedInstance.isPlaying = true
        case .paused:
            playPauseButton.setImage(UIImage(named: "Play Button"), for: .normal)
            SingletonPlayerDelegate.sharedInstance.isPlaying = false
        case .stopped:
            //reached the end of the episode:
            RealmInteractor().setEpisodeToPlayed(episode: episode!)
        default:
            return
        }
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didFindDuration duration: TimeInterval, for item: AudioItem) {
        if episode?.duration == 0 {
            RealmInteractor().setEpisodeDuration(episode: episode!, duration: duration)
            seekSlider.maximumValue = Float(duration)
            self.adjustTimeLabel(label: self.currentTimeLabel, duration: 0)
            self.adjustTimeLabel(label: self.timeRemainingLabel, duration: Int(duration))
        }

    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didUpdateProgressionTo time: TimeInterval, percentageRead: Float) {
        seekSlider.value = Float(time)
        let currentTime = Double(time)
        RealmInteractor().setEpisodeCurrentPlaybackDuration(episode: episode!, currentPlaybackDuration: Double(currentTime))
        let duration  = episode?.duration
        let timeRemaining = duration! - currentTime
        self.adjustTimeLabel(label: self.currentTimeLabel, duration: Int(currentTime))
        self.adjustTimeLabel(label: self.timeRemainingLabel, duration: Int(timeRemaining))
    }
}


//    func setUpRemoteCommandCenter() {
//        UIApplication.shared.beginReceivingRemoteControlEvents()
//        let commandCenter = MPRemoteCommandCenter.shared()
//
//        commandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
//            //Update your button here for the pause command
//            EpisodePlayer.sharedInstance.audioPlayer.pause()
//            return .success
//        }
//
//        commandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
//            EpisodePlayer.sharedInstance.audioPlayer.play()
//            return .success
//        }
//    }
//

//    func updateNowPlayingInfoForCurrentPlaybackItem() {
//        guard let currentEpisode = EpisodePlayer.sharedInstance.nowPlayingEpisode, let currentPodcast = EpisodePlayer.sharedInstance.nowPlayingPodcast else {
//            return
//        }
//        var nowPlayingInfo = [MPMediaItemPropertyTitle: currentEpisode.title! ,
//                              MPMediaItemPropertyArtist: currentPodcast.name!,
//                              MPMediaItemPropertyPlaybackDuration: currentEpisode.duration,
//                              MPNowPlayingInfoPropertyPlaybackRate: NSNumber(value: 1.0 as Float)] as [String : Any]
//        if let image = UIImage(data: currentPodcast.artwork100x100!) {
//            let size = CGSize(width: 100.0, height: 100.0)
//            let albumArt = MPMediaItemArtwork(boundsSize:size) { sz in
//                return image
//            }
//            nowPlayingInfo[MPMediaItemPropertyArtwork] = albumArt
//        }
//        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
//    }




