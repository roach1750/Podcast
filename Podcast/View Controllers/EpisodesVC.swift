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
    
    let downloadService = EpisodeDownloader()
    // Create downloadsSession here, to set self as delegate
    lazy var downloadsSession: URLSession = {
        //    let configuration = URLSessionConfiguration.default
        let configuration = URLSessionConfiguration.background(withIdentifier: "bgSessionConfiguration")
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    
    @IBOutlet var sortToolbar: UIToolbar!
    @IBOutlet var sortSegmentControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(EpisodesVC.reloadData), name: NSNotification.Name(rawValue: "newEpisodeListDownloaded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(EpisodesVC.reloadVisibleCells), name: NSNotification.Name(rawValue: "nowPlayingEpisodeDownloaded"), object: nil)
        
        refreshControl.addTarget(self, action: #selector(doTheRefresh), for: .valueChanged)

        self.tableView.addSubview(self.refreshControl)
        self.title = podcast?.name
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 60, 0)
        tableView.tableFooterView = UIView()
        downloadService.downloadsSession = downloadsSession
    }
    
    func reloadData() {
        print("reloading Data")
        let oldPodcastID = podcast!.iD
        self.podcast = RealmInteractor().fetchPodcast(withID: oldPodcastID)
        let episodes = RealmInteractor().fetchEpisodesForPodcast(podcast: self.podcast!)
        
        switch sortSegmentControl.selectedSegmentIndex {
        case 0: //All
            self.results = sortEpisodesIntoDictionary(data: episodes, unplayedOnly: false)
        case 1://Unplayed
            self.results = sortEpisodesIntoDictionary(data: episodes, unplayedOnly: true)
        default:
            return
        }
        refreshControl.endRefreshing()
        tableView.reloadData()
    }
    
    func reloadVisibleCells() {
        self.tableView.beginUpdates()
        self.tableView.reloadRows(at: self.tableView.indexPathsForVisibleRows!, with: .none)
        self.tableView.endUpdates()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        reloadData()
    }
    
    @IBAction func sortSegmentControlDidChange(_ sender: UISegmentedControl) {
        reloadData()
    }
    
    @IBAction func DeleteNewest(_ sender: UIBarButtonItem) {
        RealmInteractor().deleteNewestEpisodeForPodcast(podcast: podcast!)
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
    
    private let refreshControl = UIRefreshControl()
    
    func doTheRefresh() {
        let treadPodcastReference = ThreadSafeReference(to: podcast!)
        DispatchQueue.global(qos: .background).async {
            let realm = try! Realm()
            guard let podcast = realm.resolve(treadPodcastReference) else {
                print("Tread Problem")
                fatalError()
            }
            Downloader().downloadPodcastData(podcast: podcast, completion: nil)
        }
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
        cell.episode = episode
        cell.longDescriptionLabel.text = episode.descript
        
        //title Label 
        

        
        if episode.isPlayed {
            cell.contentView.alpha = 0.3
            if episode.isDownloaded == true {
                cell.titleLabel.text = "✅ " + episode.title! + "💾📱"
            }else {
                cell.titleLabel.text = "✅ " + episode.title!
            }
        }
        else {
            cell.contentView.alpha = 1.0
            if episode.isDownloaded == true {
                cell.titleLabel.text = episode.title! + "💾📱"
            }else {
                cell.titleLabel.text = episode.title!
            }
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
        
        //Download progress
        cell.downloadView.isHidden = true
        
//        let download = downloadService.activeDownloads[sourceURL]
//        print(downloadService.activeDownloads)

        if downloadService.activeDownloads.keys.contains(URL(string: episode.downloadURL!)!) {
            cell.downloadView.isHidden = false
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let date = self.dates![indexPath.section]
        let episode = self.results![date]![indexPath.row]
        
        let favorite = UITableViewRowAction(style: .normal, title: "⭐️") { action, index in
            RealmInteractor().markEpisodeAsFavorite(episode: episode)
        }
        favorite.backgroundColor = #colorLiteral(red: 0.3459055424, green: 0.3397476971, blue: 0.8399652839, alpha: 1)
        
        if episode.isDownloaded {
            let delete = UITableViewRowAction(style: .normal, title: "❌") { (action, index) in
                let fileName = "EpisodeData_" + (episode.guid?.replacingOccurrences(of: "/", with: ""))! + "_" + (episode.podcast?.iD)!
                FileSystemInteractor().deleteFile(fileName: fileName)
                RealmInteractor().markEpisodeAsNotDownloaded(episode: episode)
                
                tableView.beginUpdates()
                tableView.reloadRows(at: [indexPath], with: .none)
                tableView.endUpdates()
            
            }
            delete.backgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
            return [favorite,delete]
        }
        else {
            let download = UITableViewRowAction(style: .normal, title: "⇩") { (action, index) in
                self.downloadService.startDownload(episode)
                tableView.beginUpdates()
                tableView.reloadRows(at: [indexPath], with: .none)
                tableView.endUpdates()
            }
            download.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
            return [favorite,download]
        }

        
        

    }
    

    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let date = dates![indexPath.section]
        let episode = results![date]![indexPath.row]
        tableView.deselectRow(at: indexPath, animated: false)

        //If the selected episode isn't the one playing:
        if episode != ARAudioPlayer.sharedInstance.nowPlayingEpisode {
            ARAudioPlayer.sharedInstance.nowPlayingPodcast = podcast
            ARAudioPlayer.sharedInstance.nowPlayingEpisode = episode
            ARAudioPlayer.sharedInstance.startPlayingNowPlayingEpisode()
            self.tableView.beginUpdates()
            self.tableView.reloadRows(at: self.tableView.indexPathsForVisibleRows!, with: .none)
            self.tableView.endUpdates()
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
                return String(h) + " Hour " + String(m) + " Minutes"
            }
        }
    }
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    
    func getFormattedDateRelativeToToday(date: Date) -> String {
        let calendar = NSCalendar.current
        let formatter = DateFormatter()

        let date1 = calendar.startOfDay(for: date)
        let date2 = calendar.startOfDay(for: Date())
        
        let components = calendar.dateComponents([.day], from: date1, to: date2)
        
        switch components.day! {
        case 0:
            return "Today"
        case 1:
            return "Yesterday"
        case 2,3,4,5,6:
            formatter.dateFormat = "EEEE"
            let dateString = formatter.string(from: date)
            return dateString
        default:
            formatter.dateFormat = "MMMM d"
            let dateString = formatter.string(from: date)
            return dateString
        }
    }
    


}
