//
//  WatchTrasnferVC.swift
//  Podcast
//
//  Created by Andrew Roach on 9/19/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import UIKit

class WatchTransferVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var tableView: UITableView!
    @IBOutlet var transferButton: UIButton!
    @IBOutlet var statusLabel: UILabel!
    
    var latestEpisodes: [Episode]?
    var episodesToTransfer = [Episode]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        latestEpisodes = RealmInteractor().fetchLatestEpisodes()
        tableView.reloadData()
        statusLabel.isHidden = true
    }
    
    @IBAction func transferToWatchPressed(_ sender: UIButton) {
    }
    
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
