
//
//  AppDelegate.swift
//  Podcast
//
//  Created by Andrew Roach on 8/2/17.
//  Copyright © 2017 Andrew Roach. All rights reserved.
//

import UIKit
import  RealmSwift
import AVFoundation
import UserNotifications


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    var backgroundSessionCompletionHandler: (() -> Void)?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        
        //        UITabBar.appearance().backgroundImage = UIImage()
        //        UITabBar.appearance().shadowImage = UIImage()
        //        self.window?.backgroundColor = UIColor.white
        
        UNUserNotificationCenter.current().delegate = self
        
        
        Reachability.shared.startNetworkReachabilityObserver()
        
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback, mode: AVAudioSessionModeDefault)
        }
        catch {
            print("An error occured setting the audio session category: \(error)")
        }
        
        // Set the AVAudioSession as active.  This is required so that your application becomes the "Now Playing" app.
        do {
            try audioSession.setActive(true, with: [])
        }
        catch {
            print("An Error occured activating the audio session: \(error)")
            
        }
        
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert])
        { (success, error) in
            if success {
                print("Permission Granted")
            } else {
                print("Denied notification access")
            }
        }
        
        let configureationNumber = UInt64(11)
        
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: configureationNumber,
            
            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < configureationNumber) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
        })
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
        
        // Now that we've told Realm how to handle the schema change, opening the file
        // will automatically perform the migration
        _ = try! Realm()
        
        
        return true
        
    }
    
    
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession
        identifier: String, completionHandler: @escaping () -> Void) {
        backgroundSessionCompletionHandler = completionHandler
    }
    
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("background app refresh called")
        
        //        print(Reachability.shared.reachabilityManager?.networkReachabilityStatus ?? "")
        var newData = false
        let allPodcast = RealmInteractor().fetchAllSubscribedPodcast()
        for podcast in allPodcast {
            let previousEpsiodeCount = RealmInteractor().fetchEpisodesForPodcast(podcast: podcast).count
            Downloader().downloadPodcastData(podcast: podcast, completion: {
                let newEpisodeCount = RealmInteractor().fetchEpisodesForPodcast(podcast: podcast).count
                if newEpisodeCount != previousEpsiodeCount { 
                    newData = true
                    DispatchQueue.main.async {
                        let notification = UNMutableNotificationContent()
                        notification.title = "Podcast"
                        let newEpisodeCount = abs(newEpisodeCount - previousEpsiodeCount)
                        notification.body = String(newEpisodeCount) + " New Episodes Downloaded for " + podcast.name!
                        notification.userInfo = ["id": podcast.iD]
                        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                        let request = UNNotificationRequest(identifier: podcast.iD, content: notification, trigger: notificationTrigger)
                        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                    }
                }
            })
        }
        if newData == true {
            completionHandler(.newData)
        }
        else {
            completionHandler(.newData)
        }
    }
    
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        UIApplication.shared.beginReceivingRemoteControlEvents()
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [])
            print("AVAudioSession Category Playback OK")
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                print("AVAudioSession is Active")
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
        
    }
    
    
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    //this gets called when a user taps a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // TODO: this won't show when the player is playing...but that might be what I want?
        if UIApplication.shared.applicationState != .active {
                if let window = self.window, let rootViewController = window.rootViewController {
                    for vc in rootViewController.childViewControllers {
                        if vc.restorationIdentifier == "TabBarVC" {
                            (vc as! TabBarVC).selectedIndex = 1
                            let userInfo = response.notification.request.content.userInfo
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ShowEpisodesBecauseOfNotificaiton"), object: nil, userInfo: userInfo)
                        }
                    }
                }
        }
        completionHandler()
    }
    
    
    
    //This gets called when the app is on the screen and a local notificaiton is received
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        
        completionHandler([.alert])
    }
}


