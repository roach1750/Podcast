//
//  TabBarVC.swift
//  Podcast
//
//  Created by Andrew Roach on 11/29/17.
//  Copyright © 2017 Andrew Roach. All rights reserved.
//

import UIKit

class TabBarVC: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarVC.toggleTabBarView), name: NSNotification.Name(rawValue: "toggleTabBar"), object: nil)

    }

    @objc func toggleTabBarView() {
        if self.tabBar.isHidden == true {
            self.tabBar.isHidden = false
            view.bringSubview(toFront: tabBar)
            
        }
        else {
            self.tabBar.isHidden = true
        }
    }

}
