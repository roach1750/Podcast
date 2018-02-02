//
//  PlayerRemoteVC.swift
//  Podcast
//
//  Created by Andrew Roach on 11/29/17.
//  Copyright © 2017 Andrew Roach. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import RealmSwift
import NVActivityIndicatorView
import KDEAudioPlayer


class PlayerRemoteVC: UIViewController {
    
    @IBOutlet var podcastArtworkImageViewSmall: UIImageView!
    @IBOutlet var podcastTitleLabelSmall: UILabel!
    @IBOutlet var playPauseButtonSmall: UIButton!
    @IBOutlet var skipButtonSmall: UIButton!
    @IBOutlet var smallToolbarStackView: UIStackView!
    @IBOutlet weak var volumeView: UIView!
    @IBOutlet weak var routeButtonView: UIView!
    
    
    @IBOutlet var podcastArtworkImageViewLarge: UIImageView!
    @IBOutlet var titleLabelLarge: UILabel!
    
    
    @IBOutlet weak var seekSlider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    
    @IBOutlet weak var playPauseButtonLarge: UIButton!
    
    var smallActivityView: NVActivityIndicatorView?
    var largeActivityView: NVActivityIndicatorView?
    
    @IBOutlet var smallVolumeIcon: UIImageView!
    @IBOutlet var largeVolumeIcon: UIImageView!
    
    var episode: Episode? {
        didSet{
            if SingletonPlayerDelegate.sharedInstance.player.state == .buffering {
                    setUpSmallActivityView()
                setUpLabelsForAudioPlayer()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        podcastArtworkImageViewSmall.isUserInteractionEnabled = true
        podcastArtworkImageViewSmall.addGestureRecognizer(tapGestureRecognizer)
        
        let tapGestureRecognizerLarge = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        podcastArtworkImageViewLarge.isUserInteractionEnabled = true
        podcastArtworkImageViewLarge.addGestureRecognizer(tapGestureRecognizerLarge)
        
        let tapGestureRecognizerLabel = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        podcastTitleLabelSmall.isUserInteractionEnabled = true
        podcastTitleLabelSmall.addGestureRecognizer(tapGestureRecognizerLabel)
        
        let longPressGestureRecongizerForImage = UILongPressGestureRecognizer(target: self, action: #selector(longPressOnLargeImage))
        
        longPressGestureRecongizerForImage.minimumPressDuration = 1.0
        podcastArtworkImageViewLarge.isUserInteractionEnabled = true
        podcastArtworkImageViewLarge.addGestureRecognizer(longPressGestureRecongizerForImage)
        
        
        setUpVolumeView()
        setUpRouteButtonView()
        
        let inset = CGFloat(7)
        self.playPauseButtonSmall.imageEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        self.skipButtonSmall.imageEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        
        SingletonPlayerDelegate.sharedInstance.player.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(PlayerRemoteVC.configureView), name: NSNotification.Name(rawValue: "showPlayerRemote"), object: nil)
        
        
        smallVolumeIcon.image = smallVolumeIcon.image!.withRenderingMode(.alwaysTemplate)
        smallVolumeIcon.tintColor = UIColor.blue
        
        largeVolumeIcon.image = largeVolumeIcon.image!.withRenderingMode(.alwaysTemplate)
        largeVolumeIcon.tintColor = UIColor.blue
        
        NotificationCenter.default.addObserver(self, selector: #selector(PlayerRemoteVC.airplayStatusChanged), name: .MPVolumeViewWirelessRouteActiveDidChange, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PlayerRemoteVC.airplayAvailableRoutesChanged), name: .MPVolumeViewWirelessRoutesAvailableDidChange, object: nil)

        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if episode != SingletonPlayerDelegate.sharedInstance.nowPlayingEpisode {
            episode = SingletonPlayerDelegate.sharedInstance.nowPlayingEpisode
        }
        configureView()
        setUpLabelsForAudioPlayer()
        if SingletonPlayerDelegate.sharedInstance.nowPlayingPodcast?.artwork600x600 != nil {
            podcastArtworkImageViewLarge.image = UIImage(data: (SingletonPlayerDelegate.sharedInstance.nowPlayingPodcast?.artwork600x600)!)
        }
        else {
            
            //            NotificationCenter.default.addObserver(self, selector: #selector(PodcastPlayerVC.reloadImage), name: NSNotification.Name(rawValue: "podcastArtworkDownloaded"), object: nil)
        }
    }
    
    func setUpVolumeView() {
        volumeView.backgroundColor = UIColor.clear
        let myVolumeView = MPVolumeView(frame: volumeView.bounds)
        myVolumeView.showsRouteButton = false
        volumeView.addSubview(myVolumeView)
        volumeView.willMove(toWindow: self.view.window)
        volumeView.didMoveToSuperview()
    }
    
    var routeView = MPVolumeView()
    
    func setUpRouteButtonView() {
        routeView = MPVolumeView(frame: routeButtonView.bounds)
        routeView.showsVolumeSlider = false
        routeButtonView.addSubview(routeView)
        routeButtonView.backgroundColor = UIColor.clear
        changeRouteButtonColor(color: .gray)
    }
    
    func airplayStatusChanged(_ n:Notification) {
        print("Airplay Playing: \(routeView.isWirelessRouteActive)")
        if routeView.isWirelessRouteActive == true {
            changeRouteButtonColor(color: .blue)
        }
        else {
            viewDidAppear(true)///Is this really the right things to do here?
            changeRouteButtonColor(color: .gray)
        }
    }
    
    func airplayAvailableRoutesChanged(_ n: Notification) {
        print("wireless routes changed")
        print("Are wireless routes available: \(routeView.areWirelessRoutesAvailable)")
    }
    
    func changeRouteButtonColor(color: UIColor) {
        if let routeButton = routeView.subviews.last as? UIButton, let routeButtonTemplateImage  = routeButton.currentImage?.withRenderingMode(.alwaysTemplate)
        {
            routeView.setRouteButtonImage(routeButtonTemplateImage, for: .normal)
            routeView.tintColor = color
        }
    }
    
    func setUpSmallActivityView() {
        //small
        if smallActivityView != nil {
            smallActivityView?.startAnimating()
            smallActivityView?.isHidden = false
        }
        else{
            let smallImageWidth = podcastArtworkImageViewSmall.bounds.size.width
            let smallImageHeight = podcastArtworkImageViewSmall.bounds.size.height
            let frame = CGRect(x: smallImageWidth/4, y: smallImageHeight/4, width: smallImageWidth / 2, height: smallImageHeight / 2)
            smallActivityView = NVActivityIndicatorView(frame: frame, type: .lineScalePulseOut, color: .white, padding: nil)
            smallActivityView?.startAnimating()
            view.addSubview(smallActivityView!)
        }
    }
    
    func setUpLargeActivityView() {
        if largeActivityView != nil {
            largeActivityView?.startAnimating()
            largeActivityView?.isHidden = false
        }
        else {
            let largeImageWidth = podcastArtworkImageViewLarge.frame.size.width
            let largeImageHeight = podcastArtworkImageViewLarge.frame.size.height
            let frame = CGRect(x: view.frame.size.width / 2 - largeImageWidth / 8 , y: largeImageHeight/2, width: largeImageWidth / 4, height: largeImageHeight / 4)
            largeActivityView = NVActivityIndicatorView(frame: frame, type: .lineScalePulseOut, color: .white, padding: nil)
            largeActivityView?.startAnimating()
            view.addSubview(largeActivityView!)
        }
    }
    
    
    func configureView() {
        self.episode = SingletonPlayerDelegate.sharedInstance.nowPlayingEpisode
        podcastTitleLabelSmall.text = episode?.title
        titleLabelLarge.text = episode?.title
        if let artworkData = SingletonPlayerDelegate.sharedInstance.nowPlayingPodcast?.artwork600x600 {
            podcastArtworkImageViewSmall.image = UIImage(data: artworkData)
            podcastArtworkImageViewLarge.image = UIImage(data: artworkData)
        }
        
    }
    
    
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        self.view.layoutIfNeeded()
        if self.view.frame.size.height > 100 {
            goSmall()
        }
        else {
            goLarge()
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "buttonPressed"), object: nil)
    }
    
    var episodeDescriptionTextView = UITextView()
    
    func longPressOnLargeImage() {
        
        if view.subviews.contains(episodeDescriptionTextView) != true {
            episodeDescriptionTextView = UITextView(frame: podcastArtworkImageViewLarge.frame)
            episodeDescriptionTextView.text = episode?.descript
            episodeDescriptionTextView.textColor = UIColor.white
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
    
    
    let duration = 0.3
    
    func goSmall() {
        UIView.animate(withDuration: duration) {
            self.smallToolbarStackView.isHidden = false
            self.podcastArtworkImageViewLarge.isHidden = true
        }
        if SingletonPlayerDelegate.sharedInstance.player.state == .buffering {
            self.largeActivityView?.isHidden = true
            self.setUpSmallActivityView()
        }
    }
    
    func goLarge() {
        UIView.animate(withDuration: duration) {
            self.smallToolbarStackView.isHidden = true
            self.podcastArtworkImageViewLarge.isHidden = false

        }
        if SingletonPlayerDelegate.sharedInstance.player.state == .buffering {
            self.smallActivityView?.isHidden = true
            self.setUpLargeActivityView()
        }
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



extension PlayerRemoteVC: AudioPlayerDelegate {
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didChangeStateFrom from: AudioPlayerState, to state: AudioPlayerState) {
        print("did change state called from: \(from) to: \(state)")
        
        switch state {
        case .playing:
            if self.smallActivityView != nil && self.smallActivityView?.isHidden == false {
                self.smallActivityView?.stopAnimating()
                self.smallActivityView?.isHidden = true
            }
            if self.largeActivityView != nil && self.largeActivityView?.isHidden == false {
                self.largeActivityView?.stopAnimating()
                self.largeActivityView?.isHidden = true
            }
                self.playPauseButtonLarge.setImage(UIImage(named: "Pause Button"), for: .normal)
                self.playPauseButtonSmall.setImage(UIImage(named: "Pause Button"), for: .normal)
                SingletonPlayerDelegate.sharedInstance.isPlaying = true
        case .paused:
            DispatchQueue.main.async {}
                self.playPauseButtonLarge.setImage(UIImage(named: "Play Button"), for: .normal)
                self.playPauseButtonSmall.setImage(UIImage(named: "Play Button"), for: .normal)
                SingletonPlayerDelegate.sharedInstance.isPlaying = false
        case .stopped:
            //reached the end of the episode:
            RealmInteractor().setEpisodeToPlayed(episode: episode!)
        default:
            return
        }
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didFindDuration duration: TimeInterval, for item: AudioItem) {
        print("did find duration of: \(duration)")
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
        RealmInteractor().setEpisodeCurrentPlaybackDuration(episode: episode!, currentPlaybackDuration: Double(currentTime))
        let duration  = episode?.duration
        let timeRemaining = duration! - currentTime
        self.adjustTimeLabel(label: self.currentTimeLabel, duration: Int(currentTime))
        self.adjustTimeLabel(label: self.timeRemainingLabel, duration: Int(timeRemaining))
    }
}





