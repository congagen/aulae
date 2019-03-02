//
//  FeedSearchTVC.swift
//  Aumenta
//
//  Created by Tim Sandgren on 2019-02-23.
//  Copyright © 2019 Abstraqata. All rights reserved.

import UIKit
import Realm
import RealmSwift
import Foundation

class FeedSearchTVC: UITableViewController, UISearchBarDelegate {
    
    let realm = try! Realm()
    lazy var session: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var feeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()

    let feedAct = FeedActions()

    let apiUrl = "https://2hni7twyhl.execute-api.us-east-1.amazonaws.com/dev"
    var apiHeaderValue = ""
    var apiHeaderFeild = "Authorization"

    let searchTermRequestKey = "search_term"
    
    let searchStatus = "Searching..."

    var currentSearchTerm: String = "Demo"
    var searchResults: Dictionary<String, AnyObject> = [:]
    
    @IBOutlet var searchBar: UISearchBar!
    
    
    @objc func updateSearchResults(result: Dictionary<String, AnyObject> ) {
        print("updateSearchResults")

        if let resp = result["search_results"] as? Dictionary<String, AnyObject> {
            searchResults = resp
            print(searchResults)
        } else {
            searchResults = [:]
        }
        
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
    }
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("searchBarSearchButtonClicked")
        
        searchResults = [searchStatus: ""] as Dictionary<String, AnyObject>
        
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
        
        if searchBar.text != nil {
            currentSearchTerm = searchBar.text!
        }
        
        if currentSearchTerm != "" {
            let payload = [
                searchTermRequestKey: currentSearchTerm,
                "lat":  "", "long": ""
            ]
            
            NetworkTools().postReq(
                completion: updateSearchResults, apiHeaderValue: "",
                apiHeaderFeild: "", apiUrl: apiUrl,
                reqParams: payload
            )
        }
        
        view.endEditing(false)
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
        
    }
    
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if searchBar.text != nil {
            currentSearchTerm = searchBar.text!
        }
    }
    

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let keys: Array  = Array(searchResults.keys)
        
        if keys.count > 0 {
            let itemData: Dictionary<String, AnyObject> = searchResults[keys[indexPath.item]]! as! Dictionary<String, AnyObject>
            
            let itmTitle: String = keys[indexPath.item]
            let itmUrl: String = itemData["url"] as! String
            
            if feeds.filter( {$0.url == itmUrl} ).count == 0 {
                feedAct.showAddSearchFeedAlert(feedTitle: itmTitle, feedUrl: itmUrl, message: "Add this feed?", rootView: self)
            }
        }
    
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
    }

    
    @objc func asyncUrlSearch(cell: UITableViewCell, urlId: String) {
        
        if feeds.filter( {$0.url == urlId} ).count > 0 {
            cell.textLabel?.textColor = UIColor.black
        } else {
            cell.textLabel?.textColor = UIColor.lightGray
        }
        
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        print("cellForRowAt")
//        let noResultsMsg = "Your search did not match any sources"
        
        let keys: Array  = Array(searchResults.keys)
        
        if keys.count > 0 && !searchResults.keys.contains(searchStatus) {
            let itemData: Dictionary<String, AnyObject> = searchResults[keys[indexPath.item]] as! Dictionary<String, AnyObject>

            if let itmUrl = itemData["url"] as! String? {
                cell.textLabel?.text = keys[indexPath.item]
                cell.detailTextLabel?.text = itmUrl
                
//                DispatchQueue.main.async {
//                    self.asyncUrlSearch(cell: cell, urlId: itmUrl)
//                }
            }
        } else {
            cell.textLabel?.text       = searchStatus
            cell.detailTextLabel?.text = ""
            cell.textLabel?.textColor  = UIColor.black
        }
        
        return cell
    }
    
    
//    @objc func pullRefresh()  {
//        self.tableView.reloadData()
//        self.tableView.reloadInputViews()
//        rCtrl.endRefreshing()
//    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text != nil {
            searchBar.text = ""
            currentSearchTerm = searchBar.text!
        }
    }
    
    
    // --------------------------------------------------------------------------------------------------------
    
    override func viewDidDisappear(_ animated: Bool) {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        
//        rCtrl.tintColor = view.superview?.tintColor
//        tableView.addSubview(rCtrl)
//        rCtrl.addTarget(self, action: #selector(pullRefresh), for: .valueChanged)
        
    }
    
}
