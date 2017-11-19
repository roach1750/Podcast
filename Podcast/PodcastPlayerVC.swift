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

class PodcastPlayerVC: UIViewController {
    
    var episode: Episode? {
        didSet{
            print("episode set")
            setUpActivityView()
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
        setUpRemoteCommandCenter()
        setUpRouteButtonView()
        updateNowPlayingInfoForCurrentPlaybackItem()
            
        NotificationCenter.default.addObserver(self, selector: #selector(PodcastPlayerVC.playerFinishedPlaying),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: EpisodePlayer.sharedInstance.audioPlayer.currentItem)
        
        super.viewDidLoad()
    }
    
    func reloadImage() {
        if EpisodePlayer.sharedInstance.nowPlayingPodcast?.artwork600x600 != nil {
            podcastImageView.image = UIImage(data: (EpisodePlayer.sharedInstance.nowPlayingPodcast?.artwork600x600)!)
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.episode = EpisodePlayer.sharedInstance.nowPlayingEpisode
        self.titleLabel.text = episode?.title
        setUpLabelsForAudioPlayer()
        setUpPlayPauseButtonLabels()
        UIApplication.shared.statusBarStyle = .lightContent
        
        if EpisodePlayer.sharedInstance.nowPlayingPodcast?.artwork600x600 != nil {
            podcastImageView.image = UIImage(data: (EpisodePlayer.sharedInstance.nowPlayingPodcast?.artwork600x600)!)
        }
        else {
            NotificationCenter.default.addObserver(self, selector: #selector(PodcastPlayerVC.reloadImage), name: NSNotification.Name(rawValue: "podcastArtworkDownloaded"), object: nil)
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
    
    func setUpRemoteCommandCenter() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            //Update your button here for the pause command
            EpisodePlayer.sharedInstance.audioPlayer.pause()
            return .success
        }
        
        commandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            EpisodePlayer.sharedInstance.audioPlayer.play()
            return .success
        }
    }
    
    func playerFinishedPlaying() {
        print("episode finished playing")
        RealmInteractor().setEpisodeToPlayed(episode: episode!)
    }
    
    func updateNowPlayingInfoForCurrentPlaybackItem() {
        
        guard let currentEpisode = EpisodePlayer.sharedInstance.nowPlayingEpisode, let currentPodcast = EpisodePlayer.sharedInstance.nowPlayingPodcast else {
            return
        }
        
        var nowPlayingInfo = [MPMediaItemPropertyTitle: currentEpisode.title! ,
                              MPMediaItemPropertyArtist: currentPodcast.name!,
                              MPMediaItemPropertyPlaybackDuration: currentEpisode.duration,
                              MPNowPlayingInfoPropertyPlaybackRate: NSNumber(value: 1.0 as Float)] as [String : Any]
        
        if let image = UIImage(data: currentPodcast.artwork100x100!) {
            let size = CGSize(width: 100.0, height: 100.0)
            let albumArt = MPMediaItemArtwork(boundsSize:size) { sz in
                return image
            }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = albumArt
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    @IBAction func playBackSpeedButtonPressed(_ sender: UIButton) {
        if sender.titleLabel?.text == "1x" {
            playBackSpeedButton.setTitle("2x", for: .normal)
            EpisodePlayer.sharedInstance.audioPlayer.rate = 2.0
        }
        else if sender.titleLabel?.text == "2x" {
            playBackSpeedButton.setTitle("3x", for: .normal)
            EpisodePlayer.sharedInstance.audioPlayer.rate = 3.0
        }
        else if sender.titleLabel?.text == "3x" {
            playBackSpeedButton.setTitle("1/2x", for: .normal)
            EpisodePlayer.sharedInstance.audioPlayer.rate = 0.5
        }
        else if sender.titleLabel?.text == "1/2x" {
            playBackSpeedButton.setTitle("1x", for: .normal)
            EpisodePlayer.sharedInstance.audioPlayer.rate = 1.0
        }
    }
    
    @IBAction func settingsButtonPressed(_ sender: UIButton) {
        
        
    }
    
    @IBAction func seekSliderAdjusted(_ sender: UISlider) {
        EpisodePlayer.sharedInstance.seekToSeconds(seconds: Double(sender.value))
    }
    
    func setUpLabelsForAudioPlayer() {
            adjustTimeLabel(label: currentTimeLabel, duration: 0)
            adjustTimeLabel(label: timeRemainingLabel, duration: 0)
            seekSlider.setValue(0.0, animated: false)
            
            let interval = CMTimeMake(1, 1)
            EpisodePlayer.sharedInstance.audioPlayer.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { (time) in

                
                if EpisodePlayer.sharedInstance.audioPlayer.currentItem?.status == AVPlayerItemStatus.readyToPlay {
                    if (EpisodePlayer.sharedInstance.audioPlayer.currentItem?.isPlaybackLikelyToKeepUp) != nil && EpisodePlayer.sharedInstance.isPlaying == true {
                        if self.activityView != nil && self.activityView?.isHidden == false {
                            self.activityView?.stopAnimating()
                            self.activityView?.isHidden = true
                        }
                    }
                }
                
                
                let currentTime = CMTimeGetSeconds(EpisodePlayer.sharedInstance.audioPlayer.currentTime())
                guard let duration  = EpisodePlayer.sharedInstance.audioPlayer.currentItem?.duration else{
                    return
                }
            
                let timeRemaining = CMTimeGetSeconds(duration) - currentTime 
                
                guard !(timeRemaining.isNaN || timeRemaining.isInfinite) else {
                    return
                }
                
                self.adjustTimeLabel(label: self.currentTimeLabel, duration: Int(currentTime))
                
                self.adjustTimeLabel(label: self.timeRemainingLabel, duration: Int(timeRemaining))
                
                //slider - need to get this originally
                self.seekSlider.maximumValue = Float(CMTimeGetSeconds(duration)) 
                self.seekSlider.setValue(Float(currentTime), animated: true)
                
            })
            
    }
    
    func setUpPlayPauseButtonLabels() {
        if episode != nil {
        
        if EpisodePlayer.sharedInstance.isPlaying {
            playPauseButton.setImage(UIImage(named: "Pause Button"), for: .normal)
        }
        else {
            playPauseButton.setImage(UIImage(named: "Play Button"), for: .normal)
        }
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
        if EpisodePlayer.sharedInstance.isPlaying {
            EpisodePlayer.sharedInstance.audioPlayer.pause()
        }
        else {
            EpisodePlayer.sharedInstance.audioPlayer.play()
        }
        setUpPlayPauseButtonLabels()
    }
    

    @IBAction func skipForwardButtonPressed(_ sender: UIButton) {
        EpisodePlayer.sharedInstance.skipForward()
    }
    
    @IBAction func skipBackwardButtonPressed(_ sender: UIButton) {
        EpisodePlayer.sharedInstance.skipBackward()

    }
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    
    
}
