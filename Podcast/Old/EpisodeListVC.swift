//
//  EpisodeListVC.swift
//  Podcast
//
//  Created by Andrew Roach on 10/9/17.
//  Copyright © 2017 Andrew Roach. All rights reserved.
//

import UIKit
import AVFoundation

class EpisodeListVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableview: UITableView!
    var results = [Episode]()
    var episodesToSendToWatch = [Episode]()
    @IBOutlet weak var sendToWatchBarButton: UIBarButtonItem!
    
    override func viewDidLoad() {
//        results = RealmInteractor().fetchAllEpisodes()
        NotificationCenter.default.addObserver(self, selector: #selector(EpisodeListVC.reloadData), name: NSNotification.Name(rawValue: "newEpisodeListDownloaded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(EpisodeListVC.reloadData), name: NSNotification.Name(rawValue: "episodeDownloaded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(EpisodeListVC.updateProgressBar(notification:)), name: NSNotification.Name(rawValue: "episodeDownloadInProgress"), object: nil)
        reloadData()
        self.tableview.addSubview(self.refreshControl)
        super.viewDidLoad()
    }
    

    @IBAction func sendToWatchButtonPressed(_ sender: UIBarButtonItem) {
        //not editing, need to edit
        if !tableview.isEditing {
            tableview.setEditing(true, animated: true)
            self.title = "Select Episodes to Send to Watch"
            sendToWatchBarButton.title = "Next"
        }
        else {
            if episodesToSendToWatch.count > 0 {
                tableview.setEditing(false, animated: true)
                sendToWatchBarButton.title = "Send to Watch"
                self.title = ""
                self.performSegue(withIdentifier: "sendToWatchSegue", sender: episodesToSendToWatch)
                episodesToSendToWatch.removeAll()
            }
            else {
                tableview.setEditing(false, animated: true)
                sendToWatchBarButton.title = "Send to Watch"
                self.title = ""
            }
        }
    }
    
    func reloadData(){
        refreshControl.endRefreshing()
//        results = RealmInteractor().fetchAllEpisodes()
        tableview.reloadData()
    }
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
//        Downloader().downloadPodcastData()

    }
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(EpisodeListVC.handleRefresh(_:)),
                                 for: UIControlEvents.valueChanged)
        refreshControl.tintColor = UIColor.red
        
        return refreshControl
    }()
    
    
    
    var previousProgress = 0.0
    
    func updateProgressBar(notification: Notification) {
        let progress = notification.userInfo!["progress"] as! Double
        print(progress)
        let guid = notification.userInfo!["prodcastID"] as! String
        if progress > previousProgress + 0.1 {
            if let episodeIndex = results.index(where: {$0.guid == guid}) {
                let episode = results[episodeIndex]
                RealmInteractor().addDownloadProgressToEpisode(episode: episode, downloadProgress: progress)
                let indexpath = IndexPath(row: episodeIndex, section: 0)
                tableview.reloadRows(at: [indexpath], with: .none)
            }
            previousProgress = progress
        }
        else if progress == 1.0 {
            if let episodeIndex = results.index(where: {$0.guid == guid}) {
            let episode = results[episodeIndex]
                RealmInteractor().addDownloadProgressToEpisode(episode: episode, downloadProgress: 1.0)
                RealmInteractor().downloadCompleteForEpisode(episode: episode)
            let indexpath = IndexPath(row: episodeIndex, section: 0)
            tableview.reloadRows(at: [indexpath], with: .none)
            previousProgress = 0.0
            
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = results[indexPath.row]
        
        
        let nib = UINib(nibName: "EpisodeCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "episodeCell")
        let cell = tableView.dequeueReusableCell(withIdentifier: "episodeCell") as! EpisodeTableViewCell
        
        cell.titleLabel.text = result.title
        
        //specs label
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        let dateString = formatter.string(from: result.publishedDate!)
        let sizeInMB = result.fileSize / 1048576
        cell.specsLabel.text = dateString + " Duration: " + generateTimeString(duration: Int(result.duration)) + ", size: " + String(format:"%.2f", sizeInMB) + "MB"
        
        //longer description
        cell.longDescriptionLabel.text = result.descript
        
        //progressview
//        if result.isdownloadInProgress == true {
//            cell.progressView.isHidden = false
//            cell.progressView.progress = Float(result.downloadProgress)
//        }
//        else {
//            cell.progressView.isHidden = true
//        }
        //cell color
        if result.soundDataList.count != 0 {
            cell.backgroundColor = UIColor.green
        }
        else {
            cell.backgroundColor = UIColor.lightGray
        }
        
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            episodesToSendToWatch.append(results[indexPath.row])
        }
        else {
            let episode = results[indexPath.row]
            if episode.soundDataList.count == 0 {
                let PD = Downloader()
                PD.downloadInvidualEpisode(episode: episode)
            }
            else {
                //start the podcast player and go to now playing tab
                SingletonPlayerDelegate.sharedInstance.initalizeViewAndHandleEpisode(episode: episode, startPlaying: true)
                tabBarController?.selectedIndex = 2
            }
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableview.isEditing {
            episodesToSendToWatch.remove(at: episodesToSendToWatch.index(of: results[indexPath.row])!)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            let RI = RealmInteractor()
            RI.deleteEpisodeDataForEpisode(episode: results[indexPath.row])
            tableview.reloadRows(at: [indexPath], with: .none)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let episode = results[indexPath.row]
        if episode.soundDataList.count == 0 {
            return false
        }
        else {
            return true
        }
    }
    

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "sendToWatchSegue" {
            let dV = segue.destination as! SendToWatchVC
            dV.episodesToSend = (sender as? [Episode])!
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
