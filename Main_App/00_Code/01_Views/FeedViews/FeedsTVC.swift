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
    
    lazy var rlmSystem:     Results<RLM_System> = { self.realm.objects(RLM_System.self) }()
    lazy var rlmSession: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var rlmFeeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()

    var updateTimer = Timer()
    let updateInterval: Double = 10
    
    let placeholderFeedThumbImage = "Logo.png"
    
    let feedMgr = FeedMgmt()
    
    let rowHeightRatio = 0.08
    let activeColor    = UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 1)
    let nonActiveColor = UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 0.2)
    
    var newSourceAlertTextField: UITextField? = nil
    var selected: RLM_Feed? = nil
    
    
    @IBAction func closeBtnAction(_ sender: UIBarButtonItem) {
        self.navigationController?.dismiss(animated: true, completion: nil)
        self.view.removeFromSuperview()
    }
    
    
    private let rCtrl = UIRefreshControl()

    let feedAct = FeedActions()
    
    
    public var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }

    @IBAction func addBtnAction(_ sender: UIBarButtonItem) {
        showAddSourceAlert()
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
    }
    
    
    func randRange (lower: Int , upper: Int) -> Int {
        return Int(arc4random_uniform(UInt32(upper - lower)))
    }
    

    
    func handleCancel(alertView: UIAlertAction!)
    {
        print(self.newSourceAlertTextField?.text! ?? "")
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let feed = rlmFeeds[section]
        
        tableView.reloadData()
        self.tableView.reloadInputViews()

        do {
            try realm.write {
                feed.active = !feed.active
                feed.errors = 0

//                if feed.active && feed.id.lowercased() != "quickstart" {
//                    feed.name   = "Updating..."
//                }
                
            }
        } catch {
            print("Error: \(error)")
        }
        
        DispatchQueue.main.async {
            self.feedMgr.updateFeeds(checkTimeSinceUpdate: false)
        }
        
        do {
            try realm.write {
                rlmSystem.first?.needsRefresh = true
            }
        } catch {
            print("Error: \(error)")
        }
        
        tableView.reloadData()
        self.tableView.reloadInputViews()

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
            cell.detailTextLabel?.text = String(feed.sourceUrl)
        } else {
            cell.detailTextLabel?.text = feed.info
        }

        cell.restorationIdentifier = feed.id
        cell.backgroundColor = UIColor.clear
        cell.contentView.backgroundColor = UIColor.clear
        cell.accessibilityHint = String(feed.name) + " Source: " + String(feed.sourceUrl)
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
        
        feedAct.deleteFeed(feedId: feed.id, deleteFeedObjects: true, deleteFeed: true)
        
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
    }
    
    
    func urlConfigurationTextField(textField: UITextField!)
    {
        if let _ = textField {
            self.newSourceAlertTextField = textField!
            textField.text! = ""
        }
    }
    
    func handleEnterURL(alertView: UIAlertAction!) {
        
        if newSourceAlertTextField?.text != nil {
            feedAct.addNewSource(
                feedUrl: (self.newSourceAlertTextField?.text)!, feedApiKwd: "", refreshExisting: true)
        }
        
        do {
            try realm.write {
                rlmSystem.first?.needsRefresh = true
            }
        } catch {
            print("Error: \(error)")
        }
        
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
    }
    
    
    func handleEnterTopic(alertView: UIAlertAction!) {
        
        if newSourceAlertTextField?.text != nil {
            feedAct.addNewSource(feedUrl: rlmSession.first!.defaultFeedUrl, feedApiKwd: (self.newSourceAlertTextField?.text)!, refreshExisting: true)
        }
        
        do {
            try realm.write {
                rlmSystem.first?.needsRefresh = true
            }
        } catch {
            print("Error: \(error)")
        }
        
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
    }
    
    
    func showURLAlert(aMessage: String?){
        let alert = UIAlertController(
            title: "Source URL", message: nil, preferredStyle: UIAlertController.Style.alert
        )
        
        alert.addTextField(configurationHandler: urlConfigurationTextField)
        
        alert.addAction(UIAlertAction(title: "Ok",     style: UIAlertAction.Style.default, handler: handleEnterURL))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: handleCancel))
        
        alert.view.tintColor = UIColor.black
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func showTopicAlert(aMessage: String?){
        
        if rlmSession.first!.showPlaceholders {
            newSourceAlertTextField?.text = ""
        } else {
            newSourceAlertTextField?.text = "You must enable GPS content in order to view topic content"
        }
        
        let alert = UIAlertController(
            title: "Topic", message: newSourceAlertTextField?.text, preferredStyle: UIAlertController.Style.alert
        )

        alert.addTextField(configurationHandler: urlConfigurationTextField)
        
        alert.addAction(UIAlertAction(title: "Ok",     style: UIAlertAction.Style.default, handler: handleEnterTopic))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: handleCancel))
        
        alert.view.tintColor = UIColor.black
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func showAddSourceAlert() {
        let alert = UIAlertController(
            title: nil, message: nil, preferredStyle: UIAlertController.Style.alert
        )
        
        alert.addAction(UIAlertAction(title: "Add URL", style: UIAlertAction.Style.default, handler: { _ in self.showURLAlert(aMessage: "") } ))
        alert.addAction(UIAlertAction(title: "Add Topic",  style: UIAlertAction.Style.default, handler: { _ in self.showTopicAlert(aMessage: "") } ))
        alert.addAction(UIAlertAction(title: "Cancel",     style: UIAlertAction.Style.cancel,  handler: handleCancel))
        
        alert.view.tintColor = UIColor.black
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func renameConfigurationTextField(textField: UITextField!)
    {
        if let _ = textField {
            self.newSourceAlertTextField = textField!
            if selected != nil {
                self.newSourceAlertTextField?.text = selected?.name
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
    
    
    func handleEditMarketImage(feed: RLM_Feed) {
        
        do {
            try realm.write {
                if newSourceAlertTextField?.text != nil {
                    feed.customMarkerUrl = (self.newSourceAlertTextField?.text)!
                }
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    
    func editMarketAction(topicSource: RLM_Feed) {
        
        let alert = UIAlertController(
            title: "Marker URL", message: nil, preferredStyle: UIAlertController.Style.alert
        )
        
        alert.addTextField(configurationHandler: urlConfigurationTextField)
        alert.addAction(UIAlertAction(title: "Ok",     style: UIAlertAction.Style.default, handler: { _ in self.handleEditMarketImage(feed: topicSource) } ))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel,  handler: nil ))
        
        alert.view.tintColor = UIColor.black
        self.present(alert, animated: true, completion: nil)
    }
    
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let section = indexPath.section
        
        if rlmFeeds[section].id != "" {
            selected = rlmFeeds[section]
        }
        
        let shareAction = UITableViewRowAction(style: .normal, title: "Share") { (rowAction, indexPath) in
            if self.selected?.topicKwd != "" {
                self.shareURLAction(url: "Topic: " + self.selected!.topicKwd)
            } else {
                self.shareURLAction(url: (self.selected?.sourceUrl)!)
            }
        }
        shareAction.backgroundColor = UIColor.black
        
        let visitSourceLink = UITableViewRowAction(style: .normal, title: "Edit") { (rowAction, indexPath) in
             self.openUrl(scheme: (self.selected?.sourceUrl)!)
        }
        visitSourceLink.backgroundColor = UIColor.black
        
        let deleteAction = UITableViewRowAction(style: .normal, title: "Delete") { (rowAction, indexPath) in
            self.removeFeed(indexP: indexPath)
        }
        deleteAction.backgroundColor = UIColor.black
        
        let editMarkerAction = UITableViewRowAction(style: .normal, title: "Marker") { (rowAction, indexPath) in
            self.editMarketAction(topicSource: self.selected!)
        }
        editMarkerAction.backgroundColor = UIColor.black
        
//        if self.selected != nil {
//            if (self.selected?.topicKwd.count)! > 2 {
//                // return [shareAction, deleteAction, editMarkerAction]
//                return [shareAction, deleteAction]
//            } else {
//                return [shareAction, deleteAction]
//            }
//        }
        
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
