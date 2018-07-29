
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

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        
//        UITabBar.appearance().backgroundImage = UIImage()
//        UITabBar.appearance().shadowImage = UIImage()
//        self.window?.backgroundColor = UIColor.white



        
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
        
        let configureationNumber = UInt64(10)
        
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
    
//    override func remoteControlReceived(with event: UIEvent?) {
//        if let event = event {
//            SingletonPlayerDelegate.sharedInstance.player.remoteControlReceived(with: event)
//        }
//    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("background app refresh called")

        
        let podcasts = RealmInteractor().fetchAllSubscribedPodcast()
        print(podcasts.count)

        print(Thread.current)
        
        for podcast in podcasts{
            print("running loop")
            
            Downloader().downloadPodcastData(podcast: podcast)
                DispatchQueue.main.async {
                    let notification = UNMutableNotificationContent()
                    notification.title = "Podcast App"
                    notification.body = "New Episodes Downloaded for: " + podcast.name!
                    let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                    let request = UNNotificationRequest(identifier: podcast.iD, content: notification, trigger: notificationTrigger)
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                    
                    if podcast == podcasts.last {
                        print("calling completion handler")
                        completionHandler(.newData)
                        }
                    }
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
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

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

