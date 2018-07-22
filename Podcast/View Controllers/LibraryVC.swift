//
//  LibraryVC.swift
//  Podcast
//
//  Created by Andrew Roach on 10/15/17.
//  Copyright © 2017 Andrew Roach. All rights reserved.
//

import UIKit

class LibraryVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 50, 0)
        checkIfNowPlayingEpisode()
    }
    
    var results: [Podcast]?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        reloadData()
        self.title = "Subscribed"
    }

    func checkIfNowPlayingEpisode() {
        if let nowPlayingEpisode = RealmInteractor().getNowPlayingEpisode() {
            ARAudioPlayer.sharedInstance.nowPlayingPodcast = nowPlayingEpisode.podcast!
            ARAudioPlayer.sharedInstance.nowPlayingEpisode = nowPlayingEpisode
        }
    }
    
    
    func reloadData() {
        results = RealmInteractor().fetchAllSubscribedPodcast()
        tableView.reloadData()
        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let results = results {
            return results.count
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
        cell.titleLabel.text = result.name!
        cell.lastUpdatedLabel.text = RealmInteractor().getFormattedLastUpdatedDateForPodcast(podcast: result)
        if let imageData = result.artwork600x600 {
            cell.podcastImage?.image = UIImage(data: imageData)
        }
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = results![indexPath.row]
        performSegue(withIdentifier: "showEpisodes", sender: result)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            let podcast = results![indexPath.row]
            RealmInteractor().deletePodcast(podcast: podcast)
            reloadData()
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEpisodes" {
            let dVC = segue.destination as! EpisodesVC
            dVC.podcast = sender as? Podcast
            
            let backItem = UIBarButtonItem()
            backItem.title = "Back"
            navigationItem.backBarButtonItem = backItem
            
        }
    }


}
