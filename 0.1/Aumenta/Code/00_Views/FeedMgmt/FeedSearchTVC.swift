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
    
    var currentSearchTerm: String = "Demo"
    var searchResults: [String] = []
    
    
    @IBOutlet var searchBar: UISearchBar!
    
    
    
    func updateSearchResults(result: Dictionary<String,AnyObject> ) {
        print("updateSearchResults")
        searchResults.removeAll()
        searchResults = []
        
        if let feeds: NSArray = result["feeds"] as? NSArray {
            if feeds.count > 0 {
                for feed in feeds {
                    searchResults.append(feed as! String)
                }
            } else {
                searchResults.append("No Results")
            }
        } else {
            searchResults.append("No Results")
        }
        
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        if searchBar.text != nil {
            currentSearchTerm = searchBar.text!
        }
        
        if currentSearchTerm != "" {
            let payload = [
                searchTermRequestKey: currentSearchTerm,
                "lat":  "",
                "long": ""
            ]
            
            let searchResult = NetworkTools().postReq(
                completion: updateSearchResults,
                apiHeaderValue: "",
                apiHeaderFeild: "",
                apiUrl: apiUrl,
                reqParams: payload
            )
            
            print(searchResult)
        }
        
        print(currentSearchTerm)
        tableView.reloadData()
        tableView.reloadInputViews()
        tableView.scrollToRow(at: IndexPath.init(item: 0, section: 1), at: .top, animated: false)
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

        print(cell.reuseIdentifier!)
    }
    

    @objc func refresh(_ refreshControl: UIRefreshControl) {
        refreshControl.endRefreshing()
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = searchResults[indexPath.item]

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
