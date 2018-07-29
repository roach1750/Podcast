//
//  SettingsVC.swift
//  Podcast
//
//  Created by Andrew Roach on 7/28/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import UIKit

class SettingsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    var results = [Podcast: Int]()
    var keys = [Podcast]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView() 
    }
    
    override func viewWillAppear(_ animated: Bool) {
        reloadData()
    }
    
    @IBOutlet var tableView: UITableView!

    
    @IBAction func doneButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func reloadData() {
        results = FileSystemInteractor().fetchFileSizes()!
        keys = Array(results.keys)
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return keys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let podcast = keys[indexPath.row]
        cell.textLabel?.text = podcast.name
        cell.detailTextLabel?.text = formatSize(size: results[podcast]!)
        cell.imageView?.image = UIImage(data: podcast.artwork100x100!)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let podcast = keys[indexPath.row]
        let alert = UIAlertController(title: "Confirm Delete", message: "Confirm you would like to delete data for: \(podcast.name!)", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
            FileSystemInteractor().deleteFilesFor(podcast: podcast)
            self.reloadData()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    
    func formatSize(size: Int) -> String {
        let MB = Double(size) / 1000000
        return String(format: "%.01f", MB) + " MB"
    }
    
}
