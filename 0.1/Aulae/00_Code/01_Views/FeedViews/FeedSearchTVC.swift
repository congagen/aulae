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
    
    let searchTermRequestKey = "search_term"
    let searchStatus = "No sources found..."

    var currentSearchTerm: String = "Demo"
    var searchResults: Dictionary<String, AnyObject> = [:]
    let progressBar = UIProgressView()
    let loadingProgress = Progress(totalUnitCount: 100)

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
    
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if searchBar.text != nil {
            currentSearchTerm = searchBar.text!
        }
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let keys: Array  = Array(searchResults.keys)
        
        if keys.count > 0 {
            let itemData: Dictionary<String, AnyObject> = searchResults[keys[indexPath.item]]! as! Dictionary<String, AnyObject>
            
            let itmTitle: String = keys[indexPath.item]
            let itmUrl: String = itemData["url"] as! String
            
            if feeds.filter( {$0.url == itmUrl } ).count == 0 {
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
    
    
    @objc func pullRefreshCompleted() {
        rCtrl.endRefreshing()
        
        progressBar.removeFromSuperview()
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
    }
    
    
    func performSearch(_ searchBar: UISearchBar) {
        print("performSearch")
        
        NavBarOps().showProgressBar(navCtrl: self.navigationController!, progressBar: progressBar, view: self.view, timeoutPeriod: 1)
        progressBar.setProgress(1, animated: true)
        
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
                completion: updateSearchResults, apiHeaderValue: (session.first?.apiHeaderValue)!,
                apiHeaderFeild: (session.first?.apiHeaderFeild)!, apiUrl: (session.first?.feedSearchApi)!,
                reqParams: payload
            )
        }
        
        view.endEditing(false)
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
        
    }

    
    // --------------------------------------------------------------------------------------------------------
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch(searchBar)
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        self.navigationController?.popViewController(animated: true)
        progressBar.removeFromSuperview()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        progressBar.removeFromSuperview()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return screenHeight * CGFloat(rowHeightRatio)
    }

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        
        rCtrl.tintColor = view.superview?.tintColor
        tableView.addSubview(rCtrl)
        rCtrl.addTarget(self, action: #selector(pullRefreshCompleted), for: .valueChanged)
    }
    
}
