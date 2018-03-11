//
//  SearchViewController.swift
//  Podcast
//
//  Created by Andrew Roach on 10/16/17.
//  Copyright © 2017 Andrew Roach. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource   {

    

    @IBOutlet weak var searchBar: UISearchBar!

    @IBOutlet weak var tableView: UITableView!
    
    
    
    var results: [Podcast]?
    

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(SearchViewController.reloadData), name: NSNotification.Name(rawValue: "searchResultsFound"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SearchViewController.reloadData), name: NSNotification.Name(rawValue: "podcastArtworkDownloaded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SearchViewController.noResultsFound), name: NSNotification.Name(rawValue: "noSearchResultsFound"), object: nil)

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "searchResultsFound"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "podcastArtworkDownloaded"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "noSearchResultsFound"), object: nil)
    }

    
    
    func reloadData() {
        
        results = RealmInteractor().fetchAllSearchResultPodcast()
        tableView.reloadData()
        
    }
    
    func noResultsFound() {
        let alertController = UIAlertController(title: "No Results Found", message: nil, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let results = results {
            return results.count

        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = results![indexPath.row]

        let nib = UINib(nibName: "PodcastCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "podcastCell")
        let cell = tableView.dequeueReusableCell(withIdentifier: "podcastCell") as! PodcastTableViewCell
        
        cell.titleLabel.text = result.name!
        cell.lastUpdatedLabel.text = ""
        
        if let imageData = result.artwork100x100 {
            cell.podcastImage?.image = UIImage(data: imageData)
        }
        else {
            if result.artworkLink100x100 != nil {
                Downloader().downloadImageForPodcast(podcastID: result.iD, highRes: false)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = results![indexPath.row]
        Downloader().downloadPodcastData(podcast: result) {result in}
        performSegue(withIdentifier: "showEpisodes", sender: result)
    }
    

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count == 0 {
            RealmInteractor().markAllPodcastAsNotSearchResults()
            if let x = results?.count {
                if x > 0 {
                    results = nil
                    RealmInteractor().deleteUnsubscribedPodcast()
                    tableView.reloadData()
                }
            }
            searchBar.resignFirstResponder()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        RealmInteractor().markAllPodcastAsNotSearchResults()

        if let x = results?.count {
            if x > 0 {
                results = nil
                RealmInteractor().deleteUnsubscribedPodcast()
                tableView.reloadData()
            }
        }
        Downloader().searchForPodcast(searchString: searchBar.text!)
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEpisodes" {
            let dV = segue.destination as! EpisodesListSearchViewController
            dV.podcast = (sender as? Podcast)!
        }
    }
}


