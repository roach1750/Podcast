//
//  InterfaceController.swift
//  WatchPodcast Extension
//
//  Created by Andrew Roach on 9/22/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import WatchKit
import Foundation
import RealmSwift

class PodcastIC: WKInterfaceController {
    
    @IBOutlet var tableView: WKInterfaceTable!
    @IBOutlet var textLabel: WKInterfaceLabel!
    
    
    var notificationToken: NotificationToken? = nil

    
    var podcasts = [Podcast]()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        let realm = try! Realm()
        let results = realm.objects(Podcast.self)
        notificationToken = results.observe { [weak self] (changes: RealmCollectionChange) in
            switch changes {
            case .initial:
                self?.reloadTable()
                // Results are now populated and can be accessed without blocking the UI
            case .update:
                self?.reloadTable()
                // Query results have changed, so apply them to the UITableView
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(error)")
            }
        }
        
    }
    
    deinit {
        notificationToken?.invalidate()
    }
    
    
    override func willActivate() {
        super.willActivate()
        reloadTable()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    
    //table stuff
    func reloadTable() {
        podcasts = RealmInteractor().fetchAllPodcast()
        if podcasts.count != 0 {
            tableView.setNumberOfRows(podcasts.count, withRowType: "tableview")
            for (index, podcast) in podcasts.enumerated() {
                let row = tableView.rowController(at: index) as! PodcastRow
                row.titleLabel.setText(podcast.name!)
                
            }
        }
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        let podcast = podcasts[rowIndex]
        let podcastDict = ["podcast" : podcast]
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "goToMiddleControllerToViewEpisodes"), object: nil, userInfo: podcastDict)
        
    }
    
    
    
    //transfer stuff

    
    
    
    //    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
    //        let messageText = applicationContext["message"] as! String
    //        textLabel.setText(messageText)
    //        textLabel.setTextColor(UIColor(red: .random(in: 0...1),
    //                                       green: .random(in: 0...1),
    //                                       blue: .random(in: 0...1),
    //                                       alpha: 1.0))
    //    }
    //
    //    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
    //        let messageText = message["message"] as! String
    //        textLabel.setText(messageText)
    //        textLabel.setTextColor(UIColor(red: .random(in: 0...1),
    //                                       green: .random(in: 0...1),
    //                                       blue: .random(in: 0...1),
    //                                       alpha: 1.0))
    //        replyHandler([:])
    //    }
    
    
    
    
    //    @IBAction func transferUserInfo() {
    //
    //        let userInfo = ["message": "UserInfo transfer"]
    //        _ = session.transferUserInfo(userInfo)
    //        _ = session.outstandingUserInfoTransfers
    //    }
    //
    
    
    
    
    
}
