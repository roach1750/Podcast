//
//  LargePlayerRemoteVC.swift
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

class LargePlayerRemoteVC: UIViewController {
    
    @IBOutlet var podcastArtworkImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet weak var seekSlider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var volumeView: UIView!
    @IBOutlet weak var routeButtonView: UIView!
    @IBOutlet var seekSegmentedControl: UISegmentedControl!
    
    var activityView: NVActivityIndicatorView?
    
    override func viewDidLoad() {
        let tapGestureRecognizerLarge = UITapGestureRecognizer(target: self, action: #selector(self.imageTapped(_:)))
        podcastArtworkImageView.isUserInteractionEnabled = true
        podcastArtworkImageView.addGestureRecognizer(tapGestureRecognizerLarge)
        
        let longPressGestureRecongizerForImage = UILongPressGestureRecognizer(target: self, action: #selector(longPressOnImage))
        longPressGestureRecongizerForImage.minimumPressDuration = 0.50
        podcastArtworkImageView.isUserInteractionEnabled = true
        podcastArtworkImageView.addGestureRecognizer(longPressGestureRecongizerForImage)
        
        
        seekSegmentedControl.isHidden = true
        SingletonPlayerDelegate.sharedInstance.player.delegate = self
        configureView()
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(LargePlayerRemoteVC.configureArtwork), name: NSNotification.Name(rawValue: "podcastArtworkDownloaded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LargePlayerRemoteVC.newEpisodeSet), name: NSNotification.Name(rawValue: "nowPlayingEpisodeSet"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LargePlayerRemoteVC.airplayStatusChanged), name: .MPVolumeViewWirelessRouteActiveDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LargePlayerRemoteVC.airplayAvailableRoutesChanged), name: .MPVolumeViewWirelessRoutesAvailableDidChange, object: nil)
        configureArtwork()
        configurePlayPauseButton()
        setUpRouteButtonView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .default
    }
    
    func newEpisodeSet() {
        configureView()
        setUpRouteButtonView()
        
    }
    
    func imageTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func playPauseButtonPressed(_ sender: UIButton) {
        if SingletonPlayerDelegate.sharedInstance.isPlaying {
            SingletonPlayerDelegate.sharedInstance.pause()
        }
        else {
            SingletonPlayerDelegate.sharedInstance.play()
        }
    }
    
    @IBAction func seekSliderAdjusted(_ sender: UISlider) {
        SingletonPlayerDelegate.sharedInstance.player.seek(to: TimeInterval(sender.value))
    }
    
    @IBAction func skipForwardButtonPressed(_ sender: UIButton) {
        SingletonPlayerDelegate.sharedInstance.skipForward()
    }
    
    @IBAction func skipBackwardButtonPressed(_ sender: UIButton) {
        SingletonPlayerDelegate.sharedInstance.skipBackward()
        
    }
    
    @IBAction func seekSegmentedControlPress(_ sender: UISegmentedControl) {
        let title = sender.titleForSegment(at: sender.selectedSegmentIndex)
        let timeInSeconds = TimeSeekData().timeStringToSeconds(timeString: title!)
        SingletonPlayerDelegate.sharedInstance.player.seek(to: (TimeInterval(timeInSeconds)))
        
        print(timeInSeconds)
        
    }
    
    func configureArtwork() {
        if SingletonPlayerDelegate.sharedInstance.nowPlayingPodcast?.artwork600x600 != nil {
            podcastArtworkImageView.image = UIImage(data: (SingletonPlayerDelegate.sharedInstance.nowPlayingPodcast?.artwork600x600)!)
        }
    }
    
    func configureView() {
        titleLabel.text = SingletonPlayerDelegate.sharedInstance.nowPlayingEpisode?.title!
        setUpVolumeView()
        setUpSeekSegmentedControl()
        if let episode = SingletonPlayerDelegate.sharedInstance.nowPlayingEpisode {
            if episode.duration != 0 {
                let timeRemaining = episode.duration - episode.currentPlaybackDuration
                self.adjustTimeLabel(label: self.currentTimeLabel, duration: Int(episode.currentPlaybackDuration))
                self.adjustTimeLabel(label: self.timeRemainingLabel, duration: Int(timeRemaining))
                seekSlider.maximumValue = Float(episode.duration)
                seekSlider.setValue(Float(episode.currentPlaybackDuration), animated: false)
            }
            else {
                self.currentTimeLabel.text = "00:00"
                self.timeRemainingLabel.text = "00:00"
                seekSlider.maximumValue = Float(1)
                seekSlider.setValue(0, animated: false)
            }
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
    
    func setupActivityView() {
        if activityView != nil {
            activityView?.startAnimating()
            activityView?.isHidden = false
        }
        else {
            let largeImageWidth = podcastArtworkImageView.frame.size.width
            let largeImageHeight = podcastArtworkImageView.frame.size.height
            let frame = CGRect(x: view.frame.size.width / 2 - largeImageWidth / 8 , y: largeImageHeight/2, width: largeImageWidth / 4, height: largeImageHeight / 4)
            activityView = NVActivityIndicatorView(frame: frame, type: .lineScalePulseOut, color: .white, padding: nil)
            activityView?.startAnimating()
            view.addSubview(activityView!)
        }
    }

    func setUpVolumeView() {
        for volumeViewSubview in volumeView.subviews {
            if volumeViewSubview.isKind(of: MPVolumeView.self) {
                return
            }
        }
        volumeView.backgroundColor = UIColor.clear
        let myVolumeView = MPVolumeView(frame: volumeView.bounds)
        myVolumeView.showsRouteButton = false
        
        if let volumeSliderView = myVolumeView.subviews.first as? UISlider {
            volumeSliderView.minimumValueImage = UIImage(named: "SmallVolume")?.withRenderingMode(.alwaysTemplate)
            volumeSliderView.maximumValueImage = UIImage(named: "LargeVolume")?.withRenderingMode(.alwaysTemplate)
            volumeSliderView.tintColor =  _ColorLiteralType(red: 0.01864526048, green: 0.4776622653, blue: 1, alpha: 1)
            volumeSliderView.minimumTrackTintColor =  _ColorLiteralType(red: 0.01864526048, green: 0.4776622653, blue: 1, alpha: 1)
        }
        volumeView.addSubview(myVolumeView)
        
    }
    
    var routeView = MPVolumeView()
    
    func setUpRouteButtonView() {
        for volumeViewSubview in routeButtonView.subviews {
            if volumeViewSubview.isKind(of: MPVolumeView.self) {
                return
            }
        }
        
        routeView = MPVolumeView(frame: routeButtonView.bounds)
        routeView.showsVolumeSlider = false
        routeButtonView.addSubview(routeView)
        routeButtonView.backgroundColor = UIColor.clear
        changeRouteButtonColor(color: .gray)
    }
    
    func setUpSeekSegmentedControl() {
        
        seekSegmentedControl.removeAllSegments()
        let seconds = TimeSeekData().descriptionToTimeObjects(descript: SingletonPlayerDelegate.sharedInstance.nowPlayingEpisode!.descript!)
        
        for (index, second) in seconds.enumerated() {
            seekSegmentedControl.insertSegment(withTitle: TimeSeekData().secondsToString(seconds: second), at: index, animated: false)
        }
        seekSegmentedControl.isHidden = false
    }
    
    func airplayStatusChanged(_ n:Notification) {
        //        print("Airplay Playing: \(routeView.isWirelessRouteActive)")
        if routeView.isWirelessRouteActive == true {
            changeRouteButtonColor(color: .blue)
        }
        else {
            viewDidAppear(true)///Is this really the right things to do here?
            changeRouteButtonColor(color: .gray)
        }
    }
    
    func airplayAvailableRoutesChanged(_ n: Notification) {
        //        print("wireless routes changed")
        //        print("Are wireless routes available: \(routeView.areWirelessRoutesAvailable)")
    }
    
    func changeRouteButtonColor(color: UIColor) {
        if let routeButton = routeView.subviews.last as? UIButton, let routeButtonTemplateImage  = routeButton.currentImage?.withRenderingMode(.alwaysTemplate)
        {
            routeView.setRouteButtonImage(routeButtonTemplateImage, for: .normal)
            routeView.tintColor = color
        }
    }
    
    var episodeDescriptionTextView = UITextView()
    
    func longPressOnImage() {
        if view.subviews.contains(episodeDescriptionTextView) != true {
            episodeDescriptionTextView = UITextView(frame: podcastArtworkImageView.frame)
            episodeDescriptionTextView.text = SingletonPlayerDelegate.sharedInstance.nowPlayingEpisode?.descript
            episodeDescriptionTextView.textColor = UIColor.white
            episodeDescriptionTextView.font = UIFont.systemFont(ofSize: 16)
            episodeDescriptionTextView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
            episodeDescriptionTextView.isHidden = false
            episodeDescriptionTextView.isEditable = false
            episodeDescriptionTextView.isSelectable = false
            let tgr = UITapGestureRecognizer(target: self, action: #selector(hideEpisodeDescription))
            episodeDescriptionTextView.isUserInteractionEnabled = true
            episodeDescriptionTextView.addGestureRecognizer(tgr)
            view.addSubview(episodeDescriptionTextView)
        }
    }
    
    func hideEpisodeDescription() {
        episodeDescriptionTextView.removeFromSuperview()
    }
}

//audio delegate
extension LargePlayerRemoteVC: AudioPlayerDelegate {
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
            self.setupActivityView()
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
        seekSlider.maximumValue = Float(duration)
        self.adjustTimeLabel(label: self.currentTimeLabel, duration: 0)
        self.adjustTimeLabel(label: self.timeRemainingLabel, duration: Int(duration))
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didUpdateProgressionTo time: TimeInterval, percentageRead: Float) {
        seekSlider.setValue(Float(time), animated: true)
        let currentTime = Double(time)
        let episode = SingletonPlayerDelegate.sharedInstance.nowPlayingEpisode
        RealmInteractor().setEpisodeCurrentPlaybackDuration(episode: episode!, currentPlaybackDuration: Double(currentTime))
        let duration  = episode?.duration
        let timeRemaining = duration! - currentTime
        self.adjustTimeLabel(label: self.currentTimeLabel, duration: Int(currentTime))
        self.adjustTimeLabel(label: self.timeRemainingLabel, duration: Int(timeRemaining))
    }
}





//String Time Methods:
extension LargePlayerRemoteVC {
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
        else if h != 0 {
            if s < 10 {
                label.text = String(h) + ":" +  String(m) + ":" + "0" + String(s)
                if m < 10 {
                    label.text = String(h) + ":0" +  String(m) + ":" + "0" + String(s)
                    
                }
                else {
                    label.text = String(h) + ":" +  String(m) + ":" + "0" + String(s)
                }
            }
            else {
                if m < 10 {
                    label.text = String(h) + ":0" +  String(m) + ":" + String(s)
                    
                }
                else {
                    label.text = String(h) + ":" +  String(m) + ":" + String(s)
                }
            }
        }
        else {
            label.text = ""
        }
    }
    
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
}
