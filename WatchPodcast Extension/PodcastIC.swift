//
//  InterfaceController.swift
//  WatchPodcast Extension
//
//  Created by Andrew Roach on 9/22/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class PodcastIC: WKInterfaceController, WCSessionDelegate {
    
    @IBOutlet var tableView: WKInterfaceTable!
    @IBOutlet var textLabel: WKInterfaceLabel!
    
    var podcasts = [Podcast]()
    var session : WCSession!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        if WCSession.isSupported() {
            session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    
    
    override func willActivate() {
        super.willActivate()
        podcasts = RealmInteractor().fetchAllPodcast()
        reloadTable()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    
    //table stuff
    func reloadTable() {
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
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        
        //file = file url and metadata
        //file is documents inbox folder and we need to relocate it to more permanent location, if not the file will be delete after this delegate returns
        print("file received")
        textLabel.setText("file received")
        print(file.fileURL)
        if let metaData = file.metadata {
            print("episodeGuid: \(String(describing: metaData["episodeGuid"]))")
            print("episodeTitle: \(String(describing: metaData["episodeTitle"]))")
            print("podcastName: \(String(describing: metaData["podcastName"]))")
            print("podcastID: \(String(describing: metaData["podcastID"]))")
            
            let episode = Episode()
            episode.guid = metaData["episodeGuid"] as? String
            episode.title = metaData["episodeTitle"] as? String
            let podcast = Podcast()
            podcast.name = metaData["podcastName"] as? String
            podcast.iD = (metaData["podcastID"] as? String)!
            episode.podcast = podcast
            episode.podcastID = (metaData["podcastID"] as? String)!
            print("saveEpisodeCalled from - ⚡️: \(Thread.current)" + "🏭: \(OperationQueue.current?.underlyingQueue?.label ?? "None")")
            
            RealmInteractor().saveEpisode(episode: episode)
            
            
            //Need to move file -
            let dirPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                               .userDomainMask, true)
            let docsDir = dirPaths[0] as String
            let filemgr = FileManager.default
            
            do {
                try filemgr.moveItem(atPath: file.fileURL.path,
                                     toPath: docsDir + "EpisodeData_" + (episode.guid?.replacingOccurrences(of: "/", with: ""))! + "_" + (episode.podcast?.iD)!)
            } catch let error as NSError {
                print("Error moving file: \(error.description)")
            }
            
            
            self.podcasts = RealmInteractor().fetchAllPodcast()
            self.reloadTable()
            
        }
    }
    
    
    
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
