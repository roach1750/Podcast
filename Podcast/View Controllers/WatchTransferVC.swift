//
//  WatchTrasnferVC.swift
//  Podcast
//
//  Created by Andrew Roach on 9/19/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import UIKit
import WatchKit
import WatchConnectivity

class WatchTransferVC: UIViewController, UITableViewDelegate, UITableViewDataSource, WCSessionDelegate {

    


    @IBOutlet var tableView: UITableView!
    @IBOutlet var transferButton: UIButton!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var testImageView: UIImageView!
    
    var latestEpisodes: [Episode]?
    var episodesToTransfer = [Episode]()
    
    var session: WCSession!

    override func viewDidLoad() {
        super.viewDidLoad()
        if WCSession.isSupported() {
            session = WCSession.default()
            session.delegate = self
            session.activate()
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        latestEpisodes = RealmInteractor().fetchLatestEpisodes()
        tableView.reloadData()
        statusLabel.isHidden = true
    }
    
    private var fileTransferObservers = FileTransferObservers()

    
    @IBAction func transferToWatchPressed(_ sender: UIButton) {

        // Interactive Messages - both apps have to be on screen
        
//        session.sendMessage(["message": "this is a message"], replyHandler: { (replyHandler) in
//            print("reply handler: \(replyHandler)")
//        }) { (error) in
//            print("error: \(error.localizedDescription)")
//        }
        
        //Background transfer:
        
        //1. Application context - send when you have info you want to send right away, send 1 set of info
        //      updateApplicationContext(_:)
        //   Good idea to put subset of information in here and send it over, the context will override the previous context queued up
//        do {
//            let context = ["message": "this is app context message"]
//            try! session.updateApplicationContext(context)
//        }
        
        //2. User info transfer - transfer a series of dictionaries sync back progression
        //      sync back progress from watch to phone, has an outstanding queue
        //  see below method for receiver
        
        
        
        //3. File transfer - queue up a file to send
        //   Files get stored in /Documents/Inbox temporarily
        //   file can have additional metadata in form of dictionary
        //  incoming files can be group by puting identifiers in the meta data
        //  system deterimes the time to transfer
        //
        
//         let url = file location
//         let fileTransfer = session.transferFile(url,metadata:)
//         session.outstanding transfers
        
        
        
        if let episode = episodesToTransfer.first {
            
            let fileName = "EpisodeData_" + (episode.guid?.replacingOccurrences(of: "/", with: ""))! + "_" + (episode.podcast?.iD)!
            
            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = dir.appendingPathComponent(fileName)
                fileTransferObservers = FileTransferObservers()
                let metadata = ["episodeGuid" : episode.guid!, "episodeTitle" : episode.title!, "podcastName" : episode.podcast!.name!, "podcastID" : episode.podcast!.iD]
                _ = session.transferFile(fileURL, metadata: metadata)
                
                print("starting transfer of \(episode.title!)")
                
                DispatchQueue.main.async {
                    print("\(self.session.outstandingFileTransfers.count) files in the transfer queue!")
                }
                
                
                let fileTransfers = session.outstandingFileTransfers
                
                for transfer in fileTransfers {
                    fileTransferObservers.observe(transfer) { progress in
                        DispatchQueue.main.async {
                             print(progress.localizedDescription)
                            }
                        }
                    }
                }
                
                

            }
            

            
        }
        
        
        
    
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        print(userInfo)
    }
    
    
    //Watch Stuff
    
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        print(error as Any)
        DispatchQueue.main.async {
            self.statusLabel.text = "Transfer Complete"
        }
    }
    
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessionDidBecomeInactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("sessionDidDeactivate")
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        print("Paired: \(session.isPaired)")
        print("App Installed: \(session.isWatchAppInstalled)")
        print("Reachable: \(session.isReachable)") //reachabliltiy means both apps are on the screen
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print(message)
    }
    
    
    //Tableview Stuff
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (latestEpisodes?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let episode = latestEpisodes![indexPath.row]
        cell.textLabel?.text = episode.title
        if let imageData = episode.podcast?.artwork600x600 {
            cell.imageView?.image = UIImage(data: imageData)
        }
        
        if episodesToTransfer.contains(episode) {
            cell.accessoryType = .checkmark
        }
        else {
            cell.accessoryType = .none
        }
        
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        let episode = latestEpisodes![indexPath.row]
        if cell?.accessoryType == .checkmark {
            cell?.accessoryType = .none
            episodesToTransfer.remove(at: episodesToTransfer.index(of: episode)!)
        }
        else {
            episodesToTransfer.append(episode)
            cell?.accessoryType = .checkmark
        }
        tableView.deselectRow(at: indexPath, animated: true)

    }
    
}
