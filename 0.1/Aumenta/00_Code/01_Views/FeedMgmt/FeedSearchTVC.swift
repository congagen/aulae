//
//  FeedSearchTVC.swift
//  Aumenta
//
//  Created by Tim Sandgren on 2019-02-23.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import UIKit
import Realm
import RealmSwift
import Foundation


class FeedSearchTVC: UITableViewController, UISearchBarDelegate {
    
    
    let realm = try! Realm()
    lazy var session: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var feeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()

    let apiUrl = "https://2hni7twyhl.execute-api.us-east-1.amazonaws.com/dev"
    var apiHeaderValue = ""
    var apiHeaderFeild = "Authorization"

    let searchTermRequestKey = "search_term"
    
    let loadingMsg = "Searching..."
    let noResultsMsg = "Searching..."

    var currentSearchTerm: String = "Demo"
    var searchResults: [String] = []
    
    @IBOutlet var searchBar: UISearchBar!
    
    
    func updateSearchResults(result: Dictionary<String, AnyObject> ) {
        print("updateSearchResults")
        searchResults = []
        
        if let feeds: NSArray = result["feeds"] as? NSArray {
            if feeds.count > 0 {
                for feed in feeds {
                    searchResults.append(feed as! String)
                }
            } else {
                searchResults.append(noResultsMsg)
            }
        } else {
            searchResults.append(noResultsMsg)
        }
        
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
    }
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchResults = [loadingMsg]
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
        
        if searchBar.text != nil {
            currentSearchTerm = searchBar.text!
        }
        
        if currentSearchTerm != "" {
            let payload = [
                searchTermRequestKey: currentSearchTerm,
                "lat":  "",
                "long": ""
            ]
            
            NetworkTools().postReq(
                completion: updateSearchResults, apiHeaderValue: "",
                apiHeaderFeild: "", apiUrl: apiUrl,
                reqParams: payload
            )
        }
        
        print(currentSearchTerm)
        view.endEditing(false)
        
    }
    
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if searchBar.text != nil {
            currentSearchTerm = searchBar.text!
        }
    }
    

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let sUrl = self.searchResults[indexPath.item]
        
        if sUrl != noResultsMsg && sUrl != loadingMsg {
            if feeds.filter({$0.url == sUrl}).count < 1 {
                let newFeed = RLM_Feed()
                cell.contentView.backgroundColor = UIColor.blue
                
                do {
                    try realm.write {
                        if feeds.filter({$0.url == sUrl }).count == 0 {
                            
                            if sUrl != "" {
                                newFeed.url  = sUrl
                                newFeed.id   = sUrl
                                newFeed.name = "Updating..."
                                
                                self.realm.add(newFeed)
                            }
                        } else {
                            print("Feed Added: " + sUrl)
                        }
                    }
                } catch {
                    print("Error: \(error)")
                }
            }
        }
    
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
    }
    

    @objc func refresh(_ refreshControl: UIRefreshControl) {
        refreshControl.endRefreshing()
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
    }
    
    
    @objc func asyncUrlSearch(urlId: String) -> [RLM_Feed] {
        return feeds.filter( {$0.url == urlId} )
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text       = searchResults[indexPath.item]
        cell.detailTextLabel?.text = ""
        
        // TODO: Realm Async Fix
        if asyncUrlSearch(urlId: (cell.textLabel?.text)!).count > 0 {
            cell.textLabel?.textColor = UIColor.green
        } else {
            if cell.textLabel?.text != loadingMsg && cell.textLabel?.text != noResultsMsg {
                cell.textLabel?.textColor = UIColor.blue
            }
        }
        
        return cell
    }
    
    
    // --------------------------------------------------------------------------------------------------------
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        tableView.backgroundView = refreshControl
        
    }
    
}
