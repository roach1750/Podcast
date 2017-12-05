//
//  ContainerViewController.swift
//  Podcast
//
//  Created by Andrew Roach on 11/29/17.
//  Copyright © 2017 Andrew Roach. All rights reserved.
//

import UIKit

class ContainerVC: UIViewController {

    @IBOutlet var mainView: UIView!
    @IBOutlet var remoteView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(ContainerVC.buttonPressed), name: NSNotification.Name(rawValue: "buttonPressed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ContainerVC.showPlayerRemote), name: NSNotification.Name(rawValue: "showPlayerRemote"), object: nil)
        remoteView.isHidden = true
    }

    
    func showPlayerRemote() {
        remoteView.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let TBC = UITabBarController()
        let tabBarHeight = TBC.tabBar.frame.height
        let musicControlHeight = CGFloat(50)
        
        var yCord = CGFloat()
        
        if #available(iOS 11.0, *) {
             yCord = self.view.frame.height - tabBarHeight - musicControlHeight - self.view.safeAreaInsets.bottom
        } else {
             yCord = self.view.frame.height - tabBarHeight - musicControlHeight
        }
        
        self.remoteView.frame = CGRect(x: 0, y: yCord, width: self.remoteView.frame.width, height: 50)
        self.view.setNeedsDisplay()
        self.view.layoutIfNeeded()
        self.isSmall = true
    }
    
    
    var isSmall = false
    
    @objc func buttonPressed() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "toggleTabBar"), object: nil)
        let duration = 0.3
        
        
        if isSmall == false {
            UIView.animate(withDuration: duration) {
                //Moving to the toolbar controller
                let TBC = UITabBarController()
                let tabBarHeight = TBC.tabBar.frame.height
                let musicControlHeight = CGFloat(50)
                var yCord = CGFloat()

                if #available(iOS 11.0, *) {
                    yCord = self.view.frame.height - tabBarHeight - musicControlHeight - self.view.safeAreaInsets.bottom
                } else {
                     yCord = self.view.frame.height - tabBarHeight - musicControlHeight
                }
                
                self.remoteView.frame = CGRect(x: 0, y: yCord, width: self.remoteView.frame.width, height: 50)
                self.view.setNeedsDisplay()
                self.view.layoutIfNeeded()
                self.isSmall = true
            }
        }
        else {
            UIView.animate(withDuration: duration) {
                self.tabBarController?.tabBar.isHidden = true
                self.remoteView.frame = CGRect(x: 0, y: 75, width: self.remoteView.frame.width, height: self.view.frame.height)
                self.view.setNeedsDisplay()
                self.view.layoutIfNeeded()
                self.isSmall = false
            }
        }
    }
    
    
    
    

}
