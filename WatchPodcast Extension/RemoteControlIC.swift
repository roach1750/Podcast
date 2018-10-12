//
//  RemoteControlIC.swift
//  WatchPodcast Extension
//
//  Created by Andrew Roach on 9/30/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import WatchKit
import Foundation


class RemoteControlIC: WKInterfaceController {

    @IBOutlet var podcastNameLabel: WKInterfaceLabel!
    @IBOutlet var episodeNameLabel: WKInterfaceLabel!
    @IBOutlet var playPauseButton: WKInterfaceButton!
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        NotificationCenter.default.addObserver(self, selector: #selector(RemoteControlIC.becomeVisiblePage), name: NSNotification.Name(rawValue: "goToRemoteControlIC"), object: nil)
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        
        if let nowPlayingEpisode = WatchAudioPlayer.sharedInstance.nowPlayingEpisode {
            podcastNameLabel.setText(nowPlayingEpisode.podcast?.name!)
            episodeNameLabel.setText(nowPlayingEpisode.title!)
        }
        
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @objc func becomeVisiblePage() {
        becomeCurrentPage()
    }
    
    @IBAction func playPauseButtonPressed() {
        if WatchAudioPlayer.sharedInstance.audioPlayer!.isPlaying == true  {
            WatchAudioPlayer.sharedInstance.audioPlayer?.pause()
        }
        else {
            WatchAudioPlayer.sharedInstance.audioPlayer?.play()
        }
    }
    
    @IBAction func skipBackwardButtonPressed() {
    }
    
    @IBAction func skipForwardButtonPressed() {
        
    }
    
    
}
