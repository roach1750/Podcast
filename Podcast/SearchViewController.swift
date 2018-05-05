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
    
    var shouldDisplayingSearchResults = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        Downloader().downloadTopCharts()
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 50, 0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(SearchViewController.searchResultsFound), name: NSNotification.Name(rawValue: "searchResultsFound"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SearchViewController.reloadData), name: NSNotification.Name(rawValue: "podcastArtworkDownloaded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SearchViewController.noResultsFound), name: NSNotification.Name(rawValue: "noSearchResultsFound"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SearchViewController.reloadData), name: NSNotification.Name(rawValue: "topPodcastChartsDownloaded"), object: nil)

    }
    
    
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "searchResultsFound"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "podcastArtworkDownloaded"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "noSearchResultsFound"), object: nil)
    }

    func searchResultsFound() {
        shouldDisplayingSearchResults = true
        reloadData()
    }
    
    
    func reloadData() {
        if shouldDisplayingSearchResults == true {
            results = RealmInteractor().fetchAllSearchResultPodcast()
        }
        else {
            results = RealmInteractor().fetchTopCharts()
        }
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
        
        if shouldDisplayingSearchResults == true {
            let nib = UINib(nibName: "PodcastCell", bundle: nil)
            tableView.register(nib, forCellReuseIdentifier: "podcastCell")
            let cell = tableView.dequeueReusableCell(withIdentifier: "podcastCell") as! PodcastTableViewCell
            cell.lastUpdatedLabel.text = ""
            cell.titleLabel.text = result.name!
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
        else {
            let nib = UINib(nibName: "TopChartPodcastCell", bundle: nil)
            tableView.register(nib, forCellReuseIdentifier: "topChartPodcastCell")
            let cell = tableView.dequeueReusableCell(withIdentifier: "topChartPodcastCell") as! TopChartPodcastTableViewCell
            cell.rankingLabel.text = String(result.ranking)
            cell.titleLabel.text = result.name!
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
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = results![indexPath.row]
        if shouldDisplayingSearchResults == true {
            Downloader().downloadPodcastData(podcast: result) {result in}
            performSegue(withIdentifier: "showEpisodes", sender: result)
        }
        else {
            Downloader().convertTopPodcastToRealPodcast(topPodcast: result) { (podcastResult) in
                Downloader().downloadPodcastData(podcast: podcastResult) {result in}
                self.performSegue(withIdentifier: "showEpisodes", sender: result)
            }
        }
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
        shouldDisplayingSearchResults = false
        reloadData()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEpisodes" {
                let dV = segue.destination as! EpisodesListSearchViewController
                dV.podcast = (sender as? Podcast)!
        }
    
    }
}


