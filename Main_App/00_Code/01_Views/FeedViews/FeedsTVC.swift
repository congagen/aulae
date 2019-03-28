//
//  feedsTVC.swift
//  ArkitTest
//
//  Created by Tim Sandgren on 2018-05-21.
//  Copyright © 2018 Abstraqata. All rights reserved.
//

import UIKit
import Realm
import RealmSwift
import Foundation


class FeedsTVC: UITableViewController {

    let realm = try! Realm()
    lazy var rlmSession: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var rlmFeeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()

    var updateTimer = Timer()
    let updateInterval: Double = 10
    
    let placeholderFeedThumbImage = "Logo.png"
    
    let feedMgr = FeedMgmt()
    
    let rowHeightRatio = 0.11
    let activeColor    = UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 1)
    let nonActiveColor = UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 0.2)
    
    var textField: UITextField? = nil
    var selected: RLM_Feed? = nil
    
    private let rCtrl = UIRefreshControl()

    let feedAct = FeedActions()
    
    
    public var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }

    @IBAction func addBtnAction(_ sender: UIBarButtonItem) {
        addFeed()
    }
    
    
    func randRange (lower: Int , upper: Int) -> Int {
        return Int(arc4random_uniform(UInt32(upper - lower)))
    }
    
    
    func addFeed(){
        showURLAlert(aMessage: rlmSession.first?.defaultFeedUrl)
        
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
    }
    
    
    func handleCancel(alertView: UIAlertAction!)
    {
        print(self.textField?.text! ?? "")
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let feed = rlmFeeds[section]

        do {
            try realm.write {
                if !feed.deleted {
                    feed.active = !feed.active
                } else {
                    feed.active = false
                }
                
                feed.errors = 0
            }
        } catch {
            print("Error: \(error)")
        }
        
        feedMgr.updateFeeds(checkTimeSinceUpdate: false)
        
        tableView.reloadData()
    }
    

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let feed = rlmFeeds[section]
        
        // TODO: If feed.thumbImgPath != "" -> Update Image
        
        if feed.name != "" {
            cell.textLabel?.text = String(feed.name)
        } else {
            cell.textLabel?.text = "Untitled #" + String(indexPath.item)
        }
        
        if feed.info == "" {
            cell.detailTextLabel?.text = String(feed.url)
        } else {
            cell.detailTextLabel?.text = feed.info
        }

        cell.restorationIdentifier = feed.id
        cell.backgroundColor = UIColor.clear
        cell.contentView.backgroundColor = UIColor.clear
        cell.accessibilityHint = String(feed.name) + " Source: " + String(feed.url)
        cell.imageView?.image = UIImage(named: placeholderFeedThumbImage)
        
        if feed.thumbImagePath != "" {
            print("Thumb Image Path: " + feed.thumbImagePath)
            
            if let img = UIImage(contentsOfFile: feed.thumbImagePath) {
                print("Image OK")
                cell.imageView?.image = img
            } else {
                print("Thumb Image Load Error")
            }
        }
        
        //cell.imageView!.layer.cornerRadius = 10
        cell.imageView!.backgroundColor = UIColor.clear
        cell.imageView!.layer.borderWidth = 6
        cell.imageView!.layer.borderColor = UIColor.black.cgColor
        cell.imageView!.reloadInputViews()
        
        if !feed.active {
            cell.textLabel?.textColor = nonActiveColor
            cell.detailTextLabel?.textColor = nonActiveColor
        } else {
            cell.textLabel?.textColor = activeColor
            cell.detailTextLabel?.textColor = activeColor
        }
        
        return cell
    }
    

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func removeFeed(indexP: IndexPath) {
        
        let section = indexP.section
        let feed = rlmFeeds[section]
        
        feedAct.deleteFeed(feedId: feed.id, deleteFeedObjects: true, deleteFeed: false)
        
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
    }
    
    
    func urlConfigurationTextField(textField: UITextField!)
    {
        if let _ = textField {
            self.textField = textField!
            textField.text! = (rlmSession.first?.defaultFeedUrl)!
        }
    }
    
    
    func handleEnterURL(alertView: UIAlertAction!) {
        
        if textField?.text != nil {
            feedAct.addFeedUrl(feedUrl: (self.textField?.text)!, refreshExisting: true)
        }
        
        self.tableView.reloadData()
        self.tableView.reloadInputViews()

    }
    
    
    func showURLAlert(aMessage: String?){
        let alert = UIAlertController(
            title: "Add URL", message: "", preferredStyle: UIAlertController.Style.alert
        )
        
        alert.addTextField(configurationHandler: urlConfigurationTextField)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: handleCancel))
        alert.addAction(UIAlertAction(title: "Ok",     style: UIAlertAction.Style.default, handler: handleEnterURL))
        alert.view.tintColor = UIColor.black
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func renameConfigurationTextField(textField: UITextField!)
    {
        if let _ = textField {
            self.textField = textField!
            if selected != nil {
                self.textField?.text = selected?.name
            }
        }
    }
    
 
    func shareURLAction(url: String) {
        
        let textToShare = [ url ]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        // activityViewController.excludedActivityTypes = [ UIActivityType.airDrop ]
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    
    func openUrl(scheme: String) {
        if let url = URL(string: scheme) {
            if #available(iOS 10, *) {
                UIApplication.shared.open(
                    url, options: [:], completionHandler: { (success) in print("Open \(scheme): \(success)") }
                )
            } else {
                let success = UIApplication.shared.openURL(url)
                print("Open \(scheme): \(success)")
            }
        }
    }
    
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let section = indexPath.section
        
        if rlmFeeds[section].id != "" {
            selected = rlmFeeds[section]
        }
        
        let shareAction = UITableViewRowAction(style: .normal, title: "Share") { (rowAction, indexPath) in
            self.shareURLAction(url: (self.selected?.url)!)
        }
        shareAction.backgroundColor = UIColor.black
        
        let visitSourceLink = UITableViewRowAction(style: .normal, title: "WWW") { (rowAction, indexPath) in
             self.openUrl(scheme: (self.selected?.url)!)
        }
        visitSourceLink.backgroundColor = UIColor.black
        
        let deleteAction = UITableViewRowAction(style: .normal, title: "Delete") { (rowAction, indexPath) in
            self.removeFeed(indexP: indexPath)
        }
        deleteAction.backgroundColor = UIColor.black
        
        return [shareAction, deleteAction]
    }

    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return screenHeight * CGFloat(rowHeightRatio)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return rlmFeeds.filter({!$0.deleted}).count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    
    @objc func manualUpdate() {
        rCtrl.endRefreshing()
        
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavBarOps().showLogo(navCtrl: self.navigationController!, imageName: "Logo.png")

        rCtrl.tintColor = view.superview?.tintColor
        tableView.addSubview(rCtrl)
        rCtrl.addTarget(self, action: #selector(FeedsTVC.manualUpdate), for: .valueChanged)

        mainUpdate()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        manualUpdate()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
}
