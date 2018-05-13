
//
//  EpisodesListSearchViewController.swift
//  Podcast
//
//  Created by Andrew Roach on 10/19/17.
//  Copyright © 2017 Andrew Roach. All rights reserved.
//

import UIKit

class EpisodesListSearchViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var podcast: Podcast? {
        didSet {
            self.title = podcast?.name

            if podcast?.isSubscribed == true {
                changeButtonToSubcribedState()
            }
        }
    }
    
    var results: [Episode]?
    
    var topPodcast: TopPodcast?  {
        didSet {
            //Start the download
            Downloader().convertTopPodcastToPodcast(podcastToConvert: topPodcast!)
        }
    }
    
    @IBOutlet weak var podcastImageView: UIImageView!
    
    @IBOutlet weak var podcastTitleLabel: UILabel!
    
    @IBOutlet weak var subscribeButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(EpisodesListSearchViewController.reloadData), name: NSNotification.Name(rawValue: "newEpisodeListDownloaded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(EpisodesListSearchViewController.newPodcastDownloaded), name: NSNotification.Name(rawValue: "newPodcastDownloaded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(EpisodesListSearchViewController.updateArtWork), name: NSNotification.Name(rawValue: "podcastArtworkDownloaded"), object: nil)
        updateArtWork()
        podcastTitleLabel.text = podcast?.name
        podcastTitleLabel.isHidden = false
        self.tableView.addSubview(self.refreshControl)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        podcastTitleLabel.isHidden = true
    }
    
    func newPodcastDownloaded() {
        self.podcast = RealmInteractor().fetchPodcast(withID: (topPodcast?.iD)!)
        Downloader().downloadPodcastData(podcast: podcast!) {result in}
    }
    
    func updateArtWork() {
        if let art = podcast?.artwork100x100 {
            podcastImageView.image = UIImage(data: art)
        }
        else {
            Downloader().downloadImageForPodcast(podcast: podcast!, highRes: false)
        }
    }
    
    func updateEpisodes() {
        Downloader().downloadPodcastData(podcast: podcast!) {result in}
    }
    
    @IBAction func subscribeButtonPressed(_ sender: UIButton) {
        if podcast?.isSubscribed == false {
            RealmInteractor().setPodcastToSubscribed(podcast: podcast!)
            Downloader().downloadImageForPodcast(podcast: podcast!, highRes: true)
            changeButtonToSubcribedState()
        }
    }
    
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(EpisodeListVC.handleRefresh(_:)),
                                 for: UIControlEvents.valueChanged)
        refreshControl.tintColor = UIColor.red
        return refreshControl
    }()
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        Downloader().downloadPodcastData(podcast: podcast!) {result in}
    }
    
    func reloadData() {
        print("reloading table data")
        if let podcastID = self.podcast?.iD {
            self.podcast = RealmInteractor().fetchPodcast(withID: podcastID)
            self.results = RealmInteractor().fetchEpisodesForPodcast(podcast: podcast!)
        }
        refreshControl.endRefreshing()
        tableView.reloadData()
    }
    
    func changeButtonToSubcribedState() {
        subscribeButton.setImage(nil, for: .normal)
        subscribeButton.setTitle("Subscribed", for: .normal)
        subscribeButton.setTitleColor(UIColor.purple, for: .normal)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let nib = UINib(nibName: "EpisodeCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "episodeCell")
        let cell = tableView.dequeueReusableCell(withIdentifier: "episodeCell") as! EpisodeTableViewCell
        let episode = results![indexPath.row]
        cell.titleLabel.text = episode.title
        let formatter = DateFormatter()
        formatter.dateFormat = "M-dd-yy"
        let dateString = formatter.string(from: (episode.publishedDate!))
        let sizeInMB = (episode.fileSize) / 1048576
        cell.specsLabel.text = dateString + ", " + generateTimeString(duration: Int((episode.estimatedDuration))) + ", " + String(format:"%.1f", sizeInMB) + " MB"
        cell.longDescriptionLabel.text = episode.descript
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let episode = results![indexPath.row]
        
        //If the selected episode isn't the one playing:
        if episode != SingletonPlayerDelegate.sharedInstance.nowPlayingEpisode {
            SingletonPlayerDelegate.sharedInstance.nowPlayingPodcast = podcast
            SingletonPlayerDelegate.sharedInstance.initalizeViewAndHandleEpisode(episode: episode, startPlaying: true)
        }
        tableView.deselectRow(at: indexPath, animated: false)
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
