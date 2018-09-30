//
//  ExtensionDelegate.swift
//  WatchPodcast Extension
//
//  Created by Andrew Roach on 9/22/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import WatchKit
import RealmSwift
import WatchConnectivity


class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {


    var session : WCSession!

    
    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
        print("Realm location for watchOS app: \(Realm.Configuration.defaultConfiguration.fileURL!)")
        if WCSession.isSupported() {
            session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    //file transfer:
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        
        //file = file url and metadata
        //file is documents inbox folder and we need to relocate it to more permanent location, if not the file will be delete after this delegate returns
        print("file received")
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
            
        }
    }

    
    
    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    func handleRemoteNowPlayingActivity() {
            // Get visible controller
        let visibleController = WKExtension.shared().visibleInterfaceController
        
        if visibleController!.isKind(of: RemoteControlIC.self) {
            print("remote is visible")
        }
        else {
            WKInterfaceController.reloadRootPageControllers(withNames: ["RemoteControlIC"], contexts: nil, orientation: .horizontal, pageIndex: 0)
        }
    }
    

}


