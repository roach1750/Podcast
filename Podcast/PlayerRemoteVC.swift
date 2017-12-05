//
//  PlayerRemoteVC.swift
//  Podcast
//
//  Created by Andrew Roach on 11/29/17.
//  Copyright © 2017 Andrew Roach. All rights reserved.
//

import UIKit

class PlayerRemoteVC: UIViewController {

    @IBOutlet var podcastArtworkImageView: UIImageView!
    @IBOutlet var podcastTitleLabel: UILabel!
    
    
    var episode: Episode? {
        didSet{
            if SingletonPlayerDelegate.sharedInstance.player.state == .buffering {
                //add buffer
            }
        }
    }

    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        podcastArtworkImageView.isUserInteractionEnabled = true
        podcastArtworkImageView.addGestureRecognizer(tapGestureRecognizer)
        NotificationCenter.default.addObserver(self, selector: #selector(PlayerRemoteVC.configureView), name: NSNotification.Name(rawValue: "showPlayerRemote"), object: nil)
    }
    
    func configureView() {
        self.episode = SingletonPlayerDelegate.sharedInstance.nowPlayingEpisode
//        titleLabel.text = episode?.title
        podcastArtworkImageView.image = UIImage(data: (SingletonPlayerDelegate.sharedInstance.nowPlayingPodcast?.artwork600x600)!)
    }
    
    @IBOutlet var artworkWidth: NSLayoutConstraint!
    @IBOutlet var artworkCentered: NSLayoutConstraint!
    @IBOutlet var artworkLeadingToSuperview: NSLayoutConstraint!
    @IBOutlet var podcastTitleLeadingToArtwork: NSLayoutConstraint!
    @IBOutlet var podcastTitleTopToSafeArea: NSLayoutConstraint!
    @IBOutlet var podcastTitleTopToArtWork: NSLayoutConstraint!
    @IBOutlet var podcastTitleLabelCentered: NSLayoutConstraint!
    @IBOutlet var podcastTitleLabelTrailing: NSLayoutConstraint!
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        let duration = 0.3
        self.view.layoutIfNeeded()
        //going small
        
        if self.view.frame.size.height > 100 {
            artworkWidth.constant = 50
            artworkCentered.isActive = false
            artworkLeadingToSuperview.isActive = true
            podcastTitleLeadingToArtwork.isActive = true
            podcastTitleTopToSafeArea.isActive = true
            podcastTitleTopToArtWork.isActive = false
            podcastTitleLabelCentered.isActive = false
            podcastTitleLabelTrailing.isActive = true
            
        }
        //going large
        else {
            artworkWidth.constant = view.frame.size.width 
            artworkCentered.isActive = true
            artworkLeadingToSuperview.isActive = false
            podcastTitleLeadingToArtwork.isActive = false
            podcastTitleTopToSafeArea.isActive = false
            podcastTitleTopToArtWork.isActive = true
            podcastTitleLabelCentered.isActive = true
            podcastTitleLabelTrailing.isActive = false

        }
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "buttonPressed"), object: nil)
    }
    

}
