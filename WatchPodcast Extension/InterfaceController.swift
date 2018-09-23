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

class InterfaceController: WKInterfaceController, WCSessionDelegate {

    
    var session : WCSession!

    @IBOutlet var textLabel: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        if WCSession.isSupported() {
            session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        let messageText = applicationContext["message"] as! String
        textLabel.setText(messageText)
        textLabel.setTextColor(UIColor(red: .random(in: 0...1),
                                       green: .random(in: 0...1),
                                       blue: .random(in: 0...1),
                                       alpha: 1.0))
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        let messageText = message["message"] as! String
        textLabel.setText(messageText)
        textLabel.setTextColor(UIColor(red: .random(in: 0...1),
                                       green: .random(in: 0...1),
                                       blue: .random(in: 0...1),
                                       alpha: 1.0))
        replyHandler([:])
    }
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        
        //file = file url and metadata
        //file is documents inbox folder and we need to relocate it to more permanent location, if not the file will be delete after this delegate returns
        print("file received")
        let messageText = "File Transfer Complete!"
        textLabel.setText(messageText)
        
    }
    
    
    @IBAction func transferUserInfo() {
        
        let userInfo = ["message": "UserInfo transfer"]
        _ = session.transferUserInfo(userInfo)
        _ = session.outstandingUserInfoTransfers
    }
    
    
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }

}
