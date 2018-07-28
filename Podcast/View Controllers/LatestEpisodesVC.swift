//
//  LatestEpisodeVC.swift
//  Podcast
//
//  Created by Andrew Roach on 2/1/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import UIKit

class LatestEpisodesVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var tableView: UITableView!
    
    var results: [Episode]?

    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        results = RealmInteractor().fetchLatestEpisodes()
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if results != nil {
            return results!.count
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = results![indexPath.row]
        let nib = UINib(nibName: "PodcastCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "podcastCell")
        let cell = tableView.dequeueReusableCell(withIdentifier: "podcastCell") as! PodcastTableViewCell
        cell.titleLabel.text = result.title!
        cell.lastUpdatedLabel.text = result.descript!
        cell.lastUpdatedLabel.sizeToFit()
        
        if let imageData = result.podcast!.artwork600x600 {
            cell.podcastImage?.image = UIImage(data: imageData)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let episode = results![indexPath.row]
        
        //If the selected episode isn't the one playing:
        if episode != ARAudioPlayer.sharedInstance.nowPlayingEpisode {
            ARAudioPlayer.sharedInstance.nowPlayingEpisode = episode
            ARAudioPlayer.sharedInstance.startPlayingNowPlayingEpisode()
        }
        
        
        tableView.deselectRow(at: indexPath, animated: false)
    }

    
    

}
