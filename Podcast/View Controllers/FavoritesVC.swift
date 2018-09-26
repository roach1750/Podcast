//
//  Favorites.swift
//  Podcast
//
//  Created by Andrew Roach on 3/11/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import UIKit

class FavoritesVC: UIViewController,  UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var tableView: UITableView!
    
    var results: [Episode]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        reloadData()
    }
    
    func reloadData() {
        results = RealmInteractor().getFavoriteEpisodes()
        tableView.reloadData()
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results?.count ?? 0
    }
    
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let nib = UINib(nibName: "EpisodeCell", bundle: nil)
            tableView.register(nib, forCellReuseIdentifier: "episodeCell")
            let cell = tableView.dequeueReusableCell(withIdentifier: "episodeCell") as! EpisodeTableViewCell
            let episode = results![indexPath.row]
            
            cell.longDescriptionLabel.text = episode.descript
            
//            if episode.soundDataList.count > 0 {
//                cell.backgroundColor = UIColor.green
//            }else {
//                cell.backgroundColor = UIColor.white
//            }
            
            if episode.isPlayed {
                cell.contentView.alpha = 0.3
                cell.titleLabel.text = "✅ " + episode.title!
            }
            else {
                cell.titleLabel.text = episode.title
                cell.contentView.alpha = 1.0
            }
            
            if episode == ARAudioPlayer.sharedInstance.nowPlayingEpisode {
                cell.specsLabel.text = "Now Playing"
                cell.specsLabel.textColor = UIColor.green
            }
            else if episode.currentPlaybackDuration != 0 && episode.isPlayed != true {
                let timeRemaining = episode.estimatedDuration - episode.currentPlaybackDuration
                let minutesRemainingString = generateTimeString(duration: Int(timeRemaining)) + " Remaining"
                cell.specsLabel.text = minutesRemainingString
                cell.specsLabel.textColor = UIColor.red
            }
            else {
                let sizeInMB = (episode.fileSize) / 1048576
                cell.specsLabel.text =  generateTimeString(duration: Int((episode.estimatedDuration))) + ", " + String(format:"%.1f", sizeInMB) + " MB"
                cell.specsLabel.textColor = UIColor.black
            }
            
            return cell
        }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let episode = results![indexPath.row]
        
        //If the selected episode isn't the one playing:
        if episode != ARAudioPlayer.sharedInstance.nowPlayingEpisode {
            ARAudioPlayer.sharedInstance.nowPlayingPodcast = episode.podcast
            ARAudioPlayer.sharedInstance.nowPlayingEpisode = episode
        tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            let episode = results![indexPath.row]
            RealmInteractor().markEpisodeAsNotFavoirte(episode: episode)
            reloadData()
        }
    }
    
    
    
    func generateTimeString(duration: Int) -> String {
        
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: duration)
        let minuteString = s > 30 ? String(m + 1) + " Minutes": String(m) + " Minutes"
        if h == 0 {
            return minuteString
        }
        else {
            if h > 1 {
                return String(h) + " Hours" + String(m)
            }
            else {
                return String(h) + " Hour" + String(m)
            }
        }
    }
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    
    
    
    
}
