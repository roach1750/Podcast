//
//  SearchViewController.swift
//  Podcast
//
//  Created by Andrew Roach on 10/16/17.
//  Copyright © 2017 Andrew Roach. All rights reserved.
//

import UIKit
import RealmSwift

class SearchViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource    {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var searchResults: [Podcast]?
    var topChartsResults: [TopPodcast]?
    
    var searchNotificationToken: NotificationToken? = nil
    var topPodcastNotificationToken: NotificationToken? = nil
    
    deinit {
        searchNotificationToken?.invalidate()
        topPodcastNotificationToken?.invalidate()
    }
    
    var shouldDisplayingSearchResults = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        Downloader().downloadTopPodcasts()
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 50, 0)
        configureNotificationTokens()
        tableView.delegate = self
        tableView.dataSource = self
        configureTopPodcastNotificaitonToken()
        NotificationCenter.default.addObserver(self, selector: #selector(SearchViewController.reloadData), name: NSNotification.Name(rawValue: "TopPodcastsDownloaded"), object: nil)
    }
    
    @IBAction func DeleteAndReloadButtonPressed(_ sender: UIBarButtonItem) {
        Downloader().downloadTopPodcasts()
    }
    
    func configureNotificationTokens() {
        let realm = try! Realm()
        let predicate = NSPredicate(format: "isSearchResult == %@", NSNumber(value: true))
        let allSearchResultPodcast = realm.objects(Podcast.self).filter(predicate)
        searchNotificationToken = allSearchResultPodcast.observe { (changes: RealmCollectionChange) in
            switch changes {
            case .initial:
                // Results are now populated and can be accessed without blocking the UI
                print("Search Object Creation")
                
            case .update(_,  _,  _,  _):
                //                print("Deletions: \(deletions)")
                //                print("insertions: \(insertions)")
                //                print("modifications: \(modifications)")
                self.reloadData()
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(error)")
            }
        }
    }
    
    func configureTopPodcastNotificaitonToken() {
        let realm = try! Realm()
        let topPodcastResults = realm.objects(TopPodcast.self)
        topPodcastNotificationToken = topPodcastResults.observe { [weak self] (changes: RealmCollectionChange) in
            guard let tableView = self?.tableView else { return }
            switch changes {
            case .initial:
                break
            case .update(_, _, _, let modifications):
//                print("Deletions: \(deletions)")
//                print("insertions: \(insertions)")
//                print("modifications: \(modifications)")
                self?.topChartsResults = RealmInteractor().fetchTopPodcast()
                if let modificationRow = modifications.first {
                    if let updatedResult = self?.topChartsResults![modifications.first!] {
                        let indexPathForModification = IndexPath(row: modificationRow, section: 0)
                        if let cell = tableView.cellForRow(at: indexPathForModification) as? TopChartPodcastTableViewCell {
                            if let imageData = updatedResult.artwork100x100 {
                                cell.podcastImage.image = UIImage(data:imageData)
                            }
                        }
                    }
                }
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(error)")
            }
        }
    }
    
    
    
    func reloadData() {
        if shouldDisplayingSearchResults == true {
            searchResults = RealmInteractor().fetchAllSearchResultPodcast()
        }
        else {
            topChartsResults = RealmInteractor().fetchTopPodcast()
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
        if shouldDisplayingSearchResults == true {
            return searchResults?.count ?? 0
        }
        else {
            return topChartsResults?.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if shouldDisplayingSearchResults == true {
            let result = searchResults![indexPath.row]
            let nib = UINib(nibName: "PodcastCell", bundle: nil)
            tableView.register(nib, forCellReuseIdentifier: "podcastCell")
            let cell = tableView.dequeueReusableCell(withIdentifier: "podcastCell") as! PodcastTableViewCell
            cell.lastUpdatedLabel.text = ""
            cell.titleLabel.text = result.name!
            cell.podcastImage?.image = nil
            if let imageData = result.artwork100x100 {
                cell.podcastImage?.image = UIImage(data: imageData)
            }
            else {
                if result.artworkLink100x100 != nil {
                    Downloader().downloadImageForPodcast(podcast: result, highRes: false)
                    cell.podcastImage?.image = UIImage(named: "noImagePodcastImage")
                    
                }
            }
            return cell
        }
        else {
            let result = topChartsResults![indexPath.row]
            let nib = UINib(nibName: "TopChartPodcastCell", bundle: nil)
            tableView.register(nib, forCellReuseIdentifier: "topChartPodcastCell")
            let cell = tableView.dequeueReusableCell(withIdentifier: "topChartPodcastCell") as! TopChartPodcastTableViewCell
            cell.rankingLabel.text = String(result.ranking)
            cell.titleLabel.text = result.name!
            
            cell.podcastImage.layer.cornerRadius = 7.0
            cell.podcastImage.clipsToBounds = true 
            
            if let imageData = result.artwork100x100 {
                cell.podcastImage?.image = UIImage(data: imageData)
            }
            else {
                if result.artworkLink100x100 != nil {
                    Downloader().downloadImageForTopPodcast(topPodcast: result)
                    cell.podcastImage?.image = UIImage(named: "noImagePodcastImage")
                }
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if shouldDisplayingSearchResults == true {
            let result = searchResults![indexPath.row]
//            Downloader().downloadPodcastData(podcast: result)
            performSegue(withIdentifier: "showEpisodes", sender: result)
        }
        else {
            let result = topChartsResults![indexPath.row]
            performSegue(withIdentifier: "showEpisodes", sender: result)
        }
    }
    
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        print("search clicked")
        RealmInteractor().markAllPodcastAsNotSearchResults()
        RealmInteractor().deleteUnsubscribedPodcast()
        shouldDisplayingSearchResults = true
        reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count == 0 {
            RealmInteractor().markAllPodcastAsNotSearchResults()
            if let x = searchResults?.count {
                if x > 0 {
                    searchResults = nil
                    RealmInteractor().deleteUnsubscribedPodcast()
                    tableView.reloadData()
                }
            }
            searchBar.resignFirstResponder()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        RealmInteractor().markAllPodcastAsNotSearchResults()
        if let x = searchResults?.count {
            if x > 0 {
                searchResults = nil
                RealmInteractor().deleteUnsubscribedPodcast()
                reloadData()
            }
        }
        Downloader().searchForPodcast(searchString: searchBar.text!)
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        shouldDisplayingSearchResults = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        shouldDisplayingSearchResults = false
        reloadData()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEpisodes" {
            if shouldDisplayingSearchResults == true {
                let dV = segue.destination as! EpisodesListSearchViewController
                dV.podcast = (sender as? Podcast)!
            }
            else {
                let dV = segue.destination as! EpisodesListSearchViewController
                dV.topPodcast = (sender as? TopPodcast)
            }
        }
        
    }
}


