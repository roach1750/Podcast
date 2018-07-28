
//
//  EpisodesListSearchViewController.swift
//  Podcast
//
//  Created by Andrew Roach on 10/19/17.
//  Copyright © 2017 Andrew Roach. All rights reserved.
//

import UIKit
import RealmSwift

class EpisodesListSearchViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var podcastImageView: UIImageView!
    @IBOutlet weak var podcastTitleLabel: UILabel!
    @IBOutlet weak var subscribeButton: UIButton!

    var podcast: Podcast? {
        didSet {
            print("PodcastSet")
            if podcast?.isSubscribed == true {
                changeButtonToSubcribedState()
            }
            updateEpisodes()
            NotificationCenter.default.addObserver(self, selector: #selector(EpisodesListSearchViewController.reloadData), name: NSNotification.Name(rawValue: "newEpisodeListDownloaded"), object: nil)

        }
    }
    
    var results: [Episode]?
    
    var topPodcast: TopPodcast?  {
        didSet {
            Downloader().convertTopPodcastToPodcast(podcastToConvert: topPodcast!)
        }
    } 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.addSubview(self.refreshControl)
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 50, 0)

    }
    override func viewWillAppear(_ animated: Bool) {
        if topPodcast != nil {
            podcastTitleLabel.text = topPodcast?.name
            podcastTitleLabel.isHidden = false
        }
        else {
            podcastTitleLabel.text = podcast?.name
            podcastTitleLabel.isHidden = false
        }

        updateArtWork()
        setUpToken()
    }
    
    deinit {
        podcastNotificationToken?.invalidate()
    }
    
    var podcastNotificationToken: NotificationToken? = nil
    
    func setUpToken() {
        let realm = try! Realm()
        podcastNotificationToken = realm.observe { notification, realm in
            if self.topPodcast != nil {
                if let potentialNewPodcast = RealmInteractor().fetchPodcast(withID: (self.topPodcast?.iD)!) {
                if potentialNewPodcast.iD != self.podcast?.iD {
                    self.podcast = potentialNewPodcast
                    }
                }
            }
        }
    }
    
    func updateArtWork() {
        if topPodcast != nil {
            if let art = topPodcast?.artwork100x100 {
                podcastImageView.image = UIImage(data: art)
            }
        }
        else {
            if let art = podcast?.artwork100x100 {
                podcastImageView.image = UIImage(data: art)
            }
        }

    }
    
    func updateEpisodes() {
        Downloader().downloadPodcastData(podcast: podcast!)
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
            #selector(EpisodesListSearchViewController.handleRefresh(_:)),
                                 for: UIControlEvents.valueChanged)
        refreshControl.tintColor = UIColor.red
        return refreshControl
    }()
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        updateEpisodes()
    }
    
    func reloadData() {
        print("reloading table data")
        self.results = RealmInteractor().fetchEpisodesForPodcast(podcast: podcast!)
        refreshControl.endRefreshing()
        tableView.reloadData()
    }
    
    func changeButtonToSubcribedState() {
        subscribeButton.setImage(nil, for: .normal)
        subscribeButton.setTitle("Subscribed", for: .normal)
        subscribeButton.setTitleColor(UIColor.purple, for: .normal)
    }
    


    
}

//Tableview stuff
extension EpisodesListSearchViewController {
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
        if episode != ARAudioPlayer.sharedInstance.nowPlayingEpisode {
            ARAudioPlayer.sharedInstance.nowPlayingPodcast = podcast
            ARAudioPlayer.sharedInstance.nowPlayingEpisode = episode
            ARAudioPlayer.sharedInstance.startPlayingNowPlayingEpisode()
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
