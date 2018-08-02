//
//  Reachability.swift
//  Podcast
//
//  Created by Andrew Roach on 7/28/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import UIKit
import SystemConfiguration
import Alamofire

class Reachability: NSObject {
    
    //shared instance
    static let shared = Reachability()
    
    let reachabilityManager = Alamofire.NetworkReachabilityManager(host: "www.google.com")
    
    func startNetworkReachabilityObserver() {
        
        reachabilityManager?.listener = { status in
            switch status {
                
            case .notReachable:
                print("The network is not reachable")
                
            case .unknown :
                print("It is unknown whether the network is reachable")
                
            case .reachable(.ethernetOrWiFi):
                print("The network is reachable over the WiFi connection")
                
            case .reachable(.wwan):
                print("The network is reachable over the WWAN connection")
            }
        }
        // start listening
        reachabilityManager?.startListening()
    }
}


    
    

