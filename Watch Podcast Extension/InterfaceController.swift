//
//  InterfaceController.swift
//  Watch Podcast Extension
//
//  Created by Andrew Roach on 10/10/17.
//  Copyright © 2017 Andrew Roach. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity
import RealmSwift

class InterfaceController: WKInterfaceController, WCSessionDelegate {

    

    var session = WCSession.default
    var episodes: [Episode]?
    
    
    @IBOutlet var tableView: WKInterfaceTable!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
        setProperRealm()
        print(Realm.Configuration.defaultConfiguration.fileURL!)

    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        print("received file")
        var config = Realm.Configuration()
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let realmURL = documentsDirectory.appendingPathComponent("data.realm")
        if FileManager.default.fileExists(atPath: realmURL.path){
            try! FileManager.default.removeItem(at: realmURL)
        }
        try! FileManager.default.copyItem(at: file.fileURL, to: realmURL)
        config.fileURL = realmURL
        Realm.Configuration.defaultConfiguration = config
        setupTable()
    }
    

    func setupTable() {
        let realm = try! Realm()
        episodes = Array(realm.objects(Episode.self))
        if let pcast = episodes {
            if pcast.count > 0 {
                tableView.setNumberOfRows(episodes!.count, withRowType: "podcastRow")
                for i in 0..<tableView.numberOfRows {
                    if let row = tableView.rowController(at: i) as? PodcastRow {
                        row.podcastName.setText(episodes![i].title!)
                    }
            }
        }
        }
    }
    
    
    func setProperRealm() {
        var config = Realm.Configuration()
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let realmURL = documentsDirectory.appendingPathComponent("data.realm")
        config.fileURL = realmURL
        Realm.Configuration.defaultConfiguration = config
        setupTable()
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        let podcast = self.episodes![rowIndex]
        presentController(withName: "podcastPlayer", context: podcast)
    }
    
    
}
