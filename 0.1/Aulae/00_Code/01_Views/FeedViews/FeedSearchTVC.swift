//
//  FeedSearchTVC.swift
//  aulae
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

    private let rCtrl = UIRefreshControl()
    var textField: UITextField? = nil

    let rowHeightRatio = 0.1
    let activeColor    = UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 1)
    let nonActiveColor = UIColor(displayP3Red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
    
    let apiUrl = "https://2hni7twyhl.execute-api.us-east-1.amazonaws.com/dev"
    var apiHeaderValue = "VYtA9KZdQ26y4isktSKba59ME8h4WOCuajYwblvn"
    var apiHeaderFeild = "x-api-key"

    let searchTermRequestKey = "search_term"
    let searchStatus = "Searching..."

    var currentSearchTerm: String = "Demo"
    var searchResults: Dictionary<String, AnyObject> = [:]
    
    @IBOutlet var searchBar: UISearchBar!
    
    public var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
    
    @objc func refrgah(result: Dictionary<String, AnyObject>) {
        print("updateSearchResults")
        
        if let resp = result["search_results"] as? Dictionary<String, AnyObject> {
            searchResults = resp
            print(searchResults)
        } else {
            searchResults = [:]
        }
        
        self.tableView.reloadInputViews()
        self.tableView.reloadData()
    }
    
    
    @objc func updateSearchResults(result: Dictionary<String, AnyObject> ) {
        
        DispatchQueue.main.async {
            self.refrgah(result: result)
        }

    }
    
    
    func showAddSearchFeedAlert(feedTitle: String, feedUrl: String?, message: String){
        let alert = UIAlertController(
            title: feedTitle,
            message: message,
            preferredStyle: UIAlertController.Style.alert
        )
        
        alert.addAction(
            UIAlertAction(
                title: "Ok",
                style: UIAlertAction.Style.default,
                handler: { _ in self.feedAct.addFeedUrl(feedUrl: feedUrl!, refreshExisting: true) }
            )
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil ))
        alert.view.tintColor = UIColor.black
        
        self.present(
            alert, animated: true,
            completion: {
                self.tableView.reloadInputViews()
                self.tableView.reloadData()
            }
        )
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return screenHeight * CGFloat(rowHeightRatio)
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
                completion: updateSearchResults, apiHeaderValue: apiHeaderValue,
                apiHeaderFeild: apiHeaderFeild, apiUrl: apiUrl,
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
                showAddSearchFeedAlert(feedTitle: itmTitle, feedUrl: itmUrl, message: "Add this feed?")
            }
        }
    
        self.tableView.reloadInputViews()
        self.tableView.reloadData()
    }

    
    @objc func asyncUrlSearch(cell: UITableViewCell, urlId: String) {
        
        if feeds.filter( {$0.url == urlId} ).count > 0 {
            cell.textLabel?.textColor = activeColor
        } else {
            cell.textLabel?.textColor = nonActiveColor
        }
        
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
                
                DispatchQueue.main.async {
                    self.asyncUrlSearch(cell: cell, urlId: itmUrl)
                }
            }
        } else {
            cell.textLabel?.text       = searchStatus
            cell.detailTextLabel?.text = ""
            cell.textLabel?.textColor  = activeColor
        }
        
        return cell
    }
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text != nil {
            searchBar.text = ""
            currentSearchTerm = searchBar.text!
        }
    }
    
    
    @objc func manualUpdate() {
        rCtrl.endRefreshing()
        
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
        
    }
    
    
    // --------------------------------------------------------------------------------------------------------
    
    override func viewDidDisappear(_ animated: Bool) {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        
        rCtrl.tintColor = view.superview?.tintColor
        tableView.addSubview(rCtrl)
        rCtrl.addTarget(self, action: #selector(FeedsTVC.manualUpdate), for: .valueChanged)
        
    }
    
}
