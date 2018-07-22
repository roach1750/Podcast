////
////  SendToWatchVC.swift
////  Podcast
////
////  Created by Andrew Roach on 10/11/17.
////  Copyright © 2017 Andrew Roach. All rights reserved.
////
//
//import UIKit
//import WatchKit
//import WatchConnectivity
//
//class SendToWatchVC: UIViewController, UITableViewDataSource, UITableViewDelegate, WCSessionDelegate {
//
//    @IBOutlet weak var tableView: UITableView!
//    @IBOutlet weak var sendButton: UIButton!
//    
//    var episodesToSend = [Episode]()
//    
//    var session = WCSession.default()
//
//    let undownloadedEpisodeText = "Press to Download Remaining Episodes"
//    let readyToTransferEpisodeText = "Send To Watch"
//
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        NotificationCenter.default.addObserver(self, selector: #selector(SendToWatchVC.reloadData), name: NSNotification.Name(rawValue: "episodeDownloaded"), object: nil)
//        if anyUndownloadedEpisodes() == true {
//            sendButton.setTitle(undownloadedEpisodeText, for: .normal)
//        }
//        if WCSession.isSupported() {
//            session.delegate = self
//            session.activate()
//        }
//        reloadData()
//    }
//    
//    @IBAction func sendButtonPressed(_ sender: UIButton) {
//        if sender.titleLabel?.text == undownloadedEpisodeText {
//            downloadRemainingEpisodes()
//        }
//        else if sender.titleLabel?.text == readyToTransferEpisodeText {
//            beginFileTransfer()
//        }
//    }
//    
//    func reloadData(){
//        var guids = [String]()
//        for episode in episodesToSend {
//            guids.append(episode.guid!)
//        }
//        episodesToSend = RealmInteractor().fetchEpisodes(withIDs: guids)
//        
//        print(anyUndownloadedEpisodes())
//        if anyUndownloadedEpisodes() == false {
//            sendButton.setTitle(readyToTransferEpisodeText, for: .normal)
//        }
//        tableView.reloadData()
//
//    }
//    
//    
//    func anyUndownloadedEpisodes() -> Bool {
//        
//        for episodes in episodesToSend {
//            
//            if episodes.soundDataList.count == 0 {
//                return true
//            }
//        }
//        return false
//    }
//    
//    func downloadRemainingEpisodes() {
//        let PD = Downloader()
//        for episode in episodesToSend {
//            if episode.soundDataList.count == 0 {
//                PD.downloadInvidualEpisode(episode: episode)
//            }
//        }
//    }
//    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return episodesToSend.count
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "podcastCell", for: indexPath)
//        let result = episodesToSend[indexPath.row]
//        cell.textLabel?.text = result.title!
//        
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MMMM dd, yyyy"
//        let dateString = formatter.string(from: result.publishedDate!)
//        cell.detailTextLabel?.text = dateString
//        
//        //cell color
//        if result.soundDataList.count != 0 {
//            cell.backgroundColor = UIColor.green
//        }
//        else {
//            cell.backgroundColor = UIColor.lightGray
//        }
//        
//        return cell
//    }
//    
//    
//    func beginFileTransfer() {
//        print("Paired: \(session.isPaired)")
//        print("App Installed: \(session.isWatchAppInstalled)")
//        print("Reachable: \(session.isReachable)")
//        
//        let RI = RealmInteractor()
//        let path = RI.prepareRealmToTransferEpisodes(episodes: episodesToSend)
//        session.transferFile(path, metadata: nil)
//    }
//
//    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
//        print(error ?? "error is nil")
//    }
//    
//    
//    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
//        
//    }
//    
//    func sessionDidBecomeInactive(_ session: WCSession) {
//        
//    }
//    
//    func sessionDidDeactivate(_ session: WCSession) {
//        
//    }
//    
//    func sessionWatchStateDidChange(_ session: WCSession) {
//        print("Paired: \(session.isPaired)")
//        print("App Installed: \(session.isWatchAppInstalled)")
//        print("Reachable: \(session.isReachable)")
//    }
//}
