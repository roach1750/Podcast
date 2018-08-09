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
    var shouldAdjustTimeLabels = true
    
    override func viewDidLoad() {
        let tapGestureRecognizerLarge = UITapGestureRecognizer(target: self, action: #selector(self.imageTapped(_:)))
        podcastArtworkImageView.isUserInteractionEnabled = true
        podcastArtworkImageView.addGestureRecognizer(tapGestureRecognizerLarge)
        
        let longPressGestureRecongizerForImage = UILongPressGestureRecognizer(target: self, action: #selector(longPressOnImage))
        longPressGestureRecongizerForImage.minimumPressDuration = 0.50
        podcastArtworkImageView.isUserInteractionEnabled = true
        podcastArtworkImageView.addGestureRecognizer(longPressGestureRecongizerForImage)
        
        
        seekSegmentedControl.isHidden = true
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
        ARAudioPlayer.sharedInstance.delegate = self
        setUpRouteButtonView()
        
        if ARAudioPlayer.sharedInstance.nowPlayingEpisode?.duration != 0 {
            seekSlider.maximumValue = Float((ARAudioPlayer.sharedInstance.nowPlayingEpisode?.duration)!)
            seekSlider.setValue(Float((ARAudioPlayer.sharedInstance.nowPlayingEpisode?.currentPlaybackDuration)!), animated: false)
        }
        
    }
    

    
    override func viewDidAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .default
        ARAudioPlayer.sharedInstance.delegate = nil
    }
    
    func newEpisodeSet() {
        configureView()
        setUpRouteButtonView()
        
    }
    
    func imageTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func playPauseButtonPressed(_ sender: UIButton) {
        ARAudioPlayer.sharedInstance.changePausePlay()
    }
    
    @IBAction func seekSliderAdjusted(_ sender: UISlider) {
        shouldAdjustTimeLabels = false
        currentTimeLabel.textColor = #colorLiteral(red: 0.1764705882, green: 0.9960784314, blue: 0.2549019608, alpha: 1)
        seekSlider.tintColor = #colorLiteral(red: 0.2431372549, green: 0.9882352941, blue: 0.3098039216, alpha: 1)
        adjustTimeLabel(label: currentTimeLabel, duration: Int(sender.value))
    }
    
    @IBAction func sliderTouchUpInside(_ sender: UISlider) {
        touchUpOnSlider(sender)
    }
    @IBAction func sliderTouchUpOutside(_ sender: UISlider) {
        touchUpOnSlider(sender)
    }
    
    func touchUpOnSlider(_ sender: UISlider) {
        print(sender.value)
        shouldAdjustTimeLabels = true
        ARAudioPlayer.sharedInstance.seekTo(Double(sender.value))
        currentTimeLabel.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        seekSlider.tintColor = UIColor.blue
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        
    }
    
    
    @IBAction func skipForwardButtonPressed(_ sender: UIButton) {
        ARAudioPlayer.sharedInstance.skipForward()
    }
    
    @IBAction func skipBackwardButtonPressed(_ sender: UIButton) {
        ARAudioPlayer.sharedInstance.skipBackward()
        
    }
    
    @IBAction func seekSegmentedControlPress(_ sender: UISegmentedControl) {
        let title = sender.titleForSegment(at: sender.selectedSegmentIndex)
        let timeInSeconds = TimeSeekData().timeStringToSeconds(timeString: title!)
        ARAudioPlayer.sharedInstance.seekTo(Double(timeInSeconds))

        
    }
    
    
    func configureArtwork() {
        if ARAudioPlayer.sharedInstance.nowPlayingPodcast?.artwork600x600 != nil {
            podcastArtworkImageView.image = UIImage(data: (ARAudioPlayer.sharedInstance.nowPlayingPodcast?.artwork600x600)!)
        }
    }
    
    func configureView() {
        titleLabel.text = ARAudioPlayer.sharedInstance.nowPlayingEpisode?.title!
        setUpVolumeView()
        setUpSeekSegmentedControl()
        
        //delete this once I added back in the below:
        self.currentTimeLabel.text = "--:--"
        self.timeRemainingLabel.text = "--:--"
        seekSlider.setValue(0, animated: false)
        //end delete
        
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
        let seconds = TimeSeekData().descriptionToTimeObjects(descript: ARAudioPlayer.sharedInstance.nowPlayingEpisode!.descript!)
        
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
            episodeDescriptionTextView.text = ARAudioPlayer.sharedInstance.nowPlayingEpisode?.descript
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
extension LargePlayerRemoteVC: ARAudioPlayerDelegate {
    
    func didFindDuration(_sender: ARAudioPlayer, duration: Float) {
        print("did find duration of: \(duration)")

        if duration.isNaN == true {
            return 
        }
        
        
        
        DispatchQueue.main.async {
            let episode = ARAudioPlayer.sharedInstance.nowPlayingEpisode!
            if episode.duration == 0 {
                RealmInteractor().setEpisodeDuration(episode: episode, duration: Double(duration))
            }
            self.seekSlider.minimumValue = 0
            self.seekSlider.maximumValue = duration
            self.adjustTimeLabel(label: self.currentTimeLabel, duration: 0)
            self.adjustTimeLabel(label: self.timeRemainingLabel, duration: Int(duration))
        }
        

    }
    
    func progressUpdated(_sender: ARAudioPlayer, timeUpdated: Float) {
        let episode = ARAudioPlayer.sharedInstance.nowPlayingEpisode
        let duration  = episode?.duration

        if !seekSlider.isTracking {
            seekSlider.setValue(timeUpdated, animated: true)
        }
        if seekSlider.maximumValue != Float((episode?.duration)!) {
            seekSlider.minimumValue = 0
            seekSlider.maximumValue = Float(duration!)
        }
        let currentTime = Double(timeUpdated)
//        print(currentTime)
        RealmInteractor().setEpisodeCurrentPlaybackDuration(episode: episode!, currentPlaybackDuration: Double(currentTime))
        let timeRemaining = duration! - currentTime
        
        if shouldAdjustTimeLabels == true {
            self.adjustTimeLabel(label: self.currentTimeLabel, duration: Int(currentTime))
            self.adjustTimeLabel(label: self.timeRemainingLabel, duration: Int(timeRemaining))
        }
    }
    
    func didChangeState(_sender: ARAudioPlayer, oldState: AudioPlayerState, newState: AudioPlayerState) {
        configurePlayPauseButton()
        switch newState {
        case .playing:
            if self.activityView != nil && self.activityView?.isHidden == false {
                self.activityView?.stopAnimating()
                self.activityView?.isHidden = true
            }
            if self.seekSlider.maximumValue == 1 {
                didFindDuration(_sender: ARAudioPlayer.sharedInstance, duration: Float(CMTimeGetSeconds(ARAudioPlayer.sharedInstance.player.currentItem!.duration)))
            }
        case .paused:
            DispatchQueue.main.async {}
        case .buffering:
            self.setupActivityView()
        case .stopped:
            //reached the end of the episode:
            RealmInteractor().setEpisodeToPlayed(episode: ARAudioPlayer.sharedInstance.nowPlayingEpisode!)
        default:
            return
        }
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
