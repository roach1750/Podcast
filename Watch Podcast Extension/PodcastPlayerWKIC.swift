//
//  PodcastPlayerWKIC.swift
//  Watch Podcast Extension
//
//  Created by Andrew Roach on 10/11/17.
//  Copyright © 2017 Andrew Roach. All rights reserved.
//

import UIKit
import WatchKit
import AVFoundation

class PodcastPlayerWKIC: WKInterfaceController {

    
    var episode = Episode()
    
    var audioPlayer = AVAudioPlayer()

    @IBOutlet var titleLabel: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        if let episode = context as? Episode { self.episode = episode }
//        if let data = podcast.soundData {
//            try! self.audioPlayer = AVAudioPlayer(data: data)
//        }
        titleLabel.setText(episode.title!)
        self.setTitle("Back")
    }
    
    override func didDeactivate() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            print("AVAudioSession Category Playback OK")
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                print("AVAudioSession is Active")
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
    }
    
    
    
    @IBAction func playButtonPressed() {
        
            if self.audioPlayer.isPlaying {
                self.audioPlayer.pause()
            }
            else {
                self.audioPlayer.prepareToPlay()
                self.audioPlayer.play()
            }
        
    }
    
    @IBAction func previousButtonPressed() {
    }
    
    @IBAction func nextButtonPressed() {
        var currentTime = audioPlayer.currentTime
        currentTime += 15
        if currentTime > audioPlayer.duration {
            audioPlayer.stop()
        }
        else {
            audioPlayer.currentTime = currentTime
        }
    }
    
    
    
}
