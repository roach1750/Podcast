//
//  EpisodesVC.swift
//  Podcast
//
//  Created by Andrew Roach on 10/23/17.
//  Copyright © 2017 Andrew Roach. All rights reserved.
//

import UIKit
import RealmSwift

class EpisodesVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var podcast: Podcast?
    var results: [Date : [Episode]]?
    var dates: [Date]?
    
    @IBOutlet var sortToolbar: UIToolbar!
    @IBOutlet var sortSegmentControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(EpisodesVC.reloadData), name: NSNotification.Name(rawValue: "newEpisodeListDownloaded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(EpisodesVC.reloadData), name: NSNotification.Name(rawValue: "episodeDownloaded"), object: nil)
        self.tableView.addSubview(self.refreshControl)
        self.title = podcast?.name
        tableView.tableFooterView = UIView()
        reloadData()
    }
    
    func reloadData() {
        let oldPodcastID = podcast!.iD
        self.podcast = RealmInteractor().fetchPodcast(withID: oldPodcastID)
        switch sortSegmentControl.selectedSegmentIndex {
        case 0: //All
            self.results = sortEpisodesIntoDictionary(data: Array(podcast!.episodesList.sorted(byKeyPath: "publishedDate", ascending: false)), unplayedOnly: false)
        case 1://Unplayed
            self.results = sortEpisodesIntoDictionary(data: Array(podcast!.episodesList.sorted(byKeyPath: "publishedDate", ascending: false)), unplayedOnly: true)
        default:
            return
        }
        refreshControl.endRefreshing()
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        reloadData()
    }
    
    @IBAction func sortSegmentControlDidChange(_ sender: UISegmentedControl) {
        reloadData()
    }
    
    
    func sortEpisodesIntoDictionary(data: [Episode], unplayedOnly: Bool) -> [Date : [Episode]] {
        var dictionary = [Date : [Episode]]()
        for episode in data {
            if episode.isPlayed == true && unplayedOnly == true {
                continue
            }
            let calendar = Calendar.current
            let componets = calendar.dateComponents([.year,.month,.day], from: episode.publishedDate!)
            let date = calendar.date(from: componets)!
            if dictionary.keys.contains(date) {
                dictionary[date]?.append(episode)
            }
            else {
                dictionary[date] = [episode]
            }
        }
        self.dates = dictionary.keys.sorted(by: { $0.compare($1) == .orderedDescending })
        
        return dictionary
    }
   
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        
        let realm = try! Realm()
        let episodes = realm.objects(Episode.self)
        try! realm.write {
            realm.delete(episodes)
        }
        reloadData()
    }
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(EpisodesVC.handleRefresh(_:)),
                                 for: UIControlEvents.valueChanged)
        refreshControl.tintColor = UIColor.red
        return refreshControl
    }()

    func handleRefresh(_ refreshControl: UIRefreshControl) {
        Downloader().downloadPodcastData(podcast: podcast!) { result in }
    }

    
    func numberOfSections(in tableView: UITableView) -> Int {
        if let results =  dates {
            return results.count
        }else {
            return 0
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let dates = dates {
            let date = dates[section]
            
            return results![date]!.count
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let _ = results {
            let date = dates![section]
            return getFormattedDateRelativeToToday(date: date)
        }
        else {
            return ""
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let nib = UINib(nibName: "EpisodeCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "episodeCell")
        let cell = tableView.dequeueReusableCell(withIdentifier: "episodeCell") as! EpisodeTableViewCell
        let date = dates![indexPath.section]
        let episode = results![date]![indexPath.row]
        
        cell.longDescriptionLabel.text = episode.descript
        if episode.soundDataList.count > 0 {
            cell.backgroundColor = UIColor.green
        }else {
            cell.backgroundColor = UIColor.white
        }
        
        if episode.isPlayed {
            cell.contentView.alpha = 0.3
            cell.titleLabel.text = "✅ " + episode.title!
        }
        else {
            cell.titleLabel.text = episode.title
            cell.contentView.alpha = 1.0
        }
        
        if episode == SingletonPlayerDelegate.sharedInstance.nowPlayingEpisode {
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
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let favorite = UITableViewRowAction(style: .normal, title: "⭐️") { action, index in
            print("favorite button tapped")
            let date = self.dates![indexPath.section]
            let episode = self.results![date]![indexPath.row]
            RealmInteractor().markEpisodeAsFavorite(episode: episode)
        }
        favorite.backgroundColor = #colorLiteral(red: 0.3459055424, green: 0.3397476971, blue: 0.8399652839, alpha: 1)
        return [favorite]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let date = dates![indexPath.section]
        let episode = results![date]![indexPath.row]
        
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
    
    
    func getFormattedDateRelativeToToday(date: Date) -> String {
        let calendar = NSCalendar.current
        
        let date1 = calendar.startOfDay(for: date)
        let date2 = calendar.startOfDay(for: Date())
        
        let components = calendar.dateComponents([.day], from: date1, to: date2)
        
        switch components.day! {
        case 0:
            return "Today"
        case 1:
            return "Yesterday"
        case 2,3,4,5,6:
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            let dateString = formatter.string(from: date)
            return dateString
        default:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            let dateString = formatter.string(from: date)
            return dateString
        }
    }
    


}
