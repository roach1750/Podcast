//
//  EpisodeIC.swift
//  WatchPodcast Extension
//
//  Created by Andrew Roach on 9/23/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import WatchKit
import Foundation


class EpisodeIC: WKInterfaceController {

    @IBOutlet var tableView: WKInterfaceTable!
    
    @IBOutlet var titleLabel: WKInterfaceLabel!
    
    var selectedPodcast: Podcast?
    var episodes = [Episode]()

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        NotificationCenter.default.addObserver(self, selector: #selector(EpisodeIC.becomeVisiblePage), name: NSNotification.Name(rawValue: "goToMiddleControllerToViewEpisodes"), object: nil)
        
        titleLabel.setText("Title Label")

    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user

        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @objc func becomeVisiblePage(_ notification: NSNotification) {
        if let podcast = notification.userInfo!["podcast"] as? Podcast {
            selectedPodcast = podcast
            episodes = RealmInteractor().fetchEpisodesForPodcast(podcast: selectedPodcast!)
            print("Watch found \(episodes.count) episodes")
            titleLabel.setText(selectedPodcast!.name!)
            reloadTable()
            becomeCurrentPage()
        }
    }
    
    
    
    func reloadTable() {
        print("Reload Table: ⚡️: \(Thread.current)" + "🏭: \(OperationQueue.current?.underlyingQueue?.label ?? "None")")

        if episodes.count != 0 {
            tableView.setNumberOfRows(episodes.count, withRowType: "tableview")
            for (index, episode) in episodes.enumerated() {
                let row = tableView.rowController(at: index) as! PodcastRow
                print(episode.title)
                DispatchQueue.main.async {
                    row.titleLabel.setText(episode.title!)
                }
            }
        }
    }
    
    
}
