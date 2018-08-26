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
    
    var results: [Date: [Episode]]?
    var dates: [Date]?


    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        results = RealmInteractor().fetchLatestEpisodesNumberOfEpisodesGroupedIntoDates(numberOfEpsiosdes: 25)
        dates = results?.keys.sorted(by: { $0.compare($1) == .orderedDescending })

        tableView.reloadData()
    }
    
    
    
    
    //tableview
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let dates = dates {
            let date = dates[section]
            
            return results![date]!.count
        }
        else {
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if let results =  dates {
            return results.count
        }else {
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
        let date = dates![indexPath.section]
        let result = results![date]![indexPath.row]
        let nib = UINib(nibName: "PodcastCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "podcastCell")
        let cell = tableView.dequeueReusableCell(withIdentifier: "podcastCell") as! PodcastTableViewCell
        cell.titleLabel.text = result.title!
        cell.titleLabel.font = cell.titleLabel.font.withSize(16)
        cell.lastUpdatedLabel.text = nil
        if let imageData = result.podcast!.artwork600x600 {
            cell.podcastImage?.image = UIImage(data: imageData)
            cell.podcastImage.layer.cornerRadius = 7.0
            cell.podcastImage.clipsToBounds = true
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let date = dates![indexPath.section]
        let episode = results![date]![indexPath.row]
        
        //If the selected episode isn't the one playing:
        if episode != ARAudioPlayer.sharedInstance.nowPlayingEpisode {
            ARAudioPlayer.sharedInstance.nowPlayingPodcast = episode.podcast
            ARAudioPlayer.sharedInstance.nowPlayingEpisode = episode
            ARAudioPlayer.sharedInstance.startPlayingNowPlayingEpisode()
        }
        
        
        tableView.deselectRow(at: indexPath, animated: false)
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
