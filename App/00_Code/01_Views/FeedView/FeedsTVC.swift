//
//  feedsTVC.swift
//  ArkitTest
//
//  Created by Tim Sandgren on 2018-05-21.
//  Copyright © 2018 Tim Sandgren. All rights reserved.
//

import UIKit
import Realm
import RealmSwift
import Foundation


class FeedsTVC: UITableViewController {

    lazy var realm = try! Realm()
    
    lazy var rlmSystem: Results<RLM_SysSettings_117> = { self.realm.objects(RLM_SysSettings_117.self) }()
    lazy var rlmSession: Results<RLM_Session_117> = { self.realm.objects(RLM_Session_117.self) }()
    lazy var rlmFeeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()

    var updateTimer = Timer()
    let updateInterval: Double = 10
    
    let placeholderFeedThumbImage = "FeedLogo2.png"
    
    let feedMgr = FeedMgmt()
    
    let rowHeightRatio = 0.08
    let activeColor    = UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 1)
    let nonActiveColor = UIColor(displayP3Red: 0.35, green: 0.35, blue: 0.35, alpha: 1)
    
    var alertTextField: UITextField? = nil
    var alertTextFieldB: UITextField? = nil
    
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
        print(self.alertTextField?.text! ?? "")
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let feed = rlmFeeds[section]
        
        self.tableView.reloadData()
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
                rlmSession.first?.needsRefresh = true
            }
        } catch {
            print("Error: \(error)")
        }
        
        self.tableView.reloadData()
        self.tableView.reloadInputViews()

    }
    
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        var footerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 0))
        footerView.backgroundColor = .clear

        if section == (tableView.numberOfSections - 1) {
            footerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 50))
        }
        
        return footerView

    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        if section == (tableView.numberOfSections - 1) {
            return 50
        } else {
            return 0
        }
        
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
        
        if feed.errors > 5 {
            cell.detailTextLabel?.text = "Offline"
        }

        cell.restorationIdentifier = feed.id
        cell.backgroundColor = UIColor.clear
        cell.contentView.backgroundColor = UIColor.clear
        cell.accessibilityHint = String(feed.name) + " Source: " + String(feed.sourceUrl)
        cell.imageView?.image = UIImage(named: placeholderFeedThumbImage)
        
        if feed.thumbImagePath != "" {
            print("Thumb Image Path: " + feed.thumbImagePath)
            
            if let img = UIImage(contentsOfFile: feed.thumbImagePath) {
                cell.imageView?.image = img                
            } else {
                print("Thumb Image Load Error")
            }
        }
        
        //cell.imageView!.layer.cornerRadius = 10
        cell.imageView!.backgroundColor = UIColor.clear
        cell.imageView!.layer.borderWidth = 6
        cell.imageView!.layer.borderColor = UIColor.clear.cgColor
        cell.imageView!.reloadInputViews()
        
        if !feed.active {
            cell.imageView?.alpha = 0.35
            cell.textLabel?.textColor = nonActiveColor
            cell.detailTextLabel?.textColor = nonActiveColor
        } else {
            cell.imageView?.alpha = 1
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
            self.alertTextField = textField!
            textField.text! = ""
        }
    }
    
    func urlConfigurationTextFieldNumPad(textField: UITextField!)
    {
        if let _ = textField {
            textField.keyboardType = .numberPad
            self.alertTextFieldB = textField!
            textField.text! = ""
        }
    }
    
    
    func handleEnterURL(alertView: UIAlertAction!) {
        
        if alertTextField?.text != nil {
            feedAct.addNewSource(
                feedUrl: (self.alertTextField?.text)!, feedApiKwd: "", refreshExisting: true)
        }
        
        do {
            try realm.write {
                rlmSession.first?.needsRefresh = true
            }
        } catch {
            print("Error: \(error)")
        }
        
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
    }
    
    
    func handleEnterTopic(alertView: UIAlertAction!) {
        
        if alertTextField?.text != nil {
            feedAct.addNewSource(feedUrl: rlmSystem.first!.defaultFeedUrl, feedApiKwd: (self.alertTextField?.text)!, refreshExisting: true)
        }
        
        do {
            try realm.write {
                rlmSession.first?.needsRefresh = true
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
        
        if traitCollection.userInterfaceStyle == .light {
            alert.view.tintColor = UIColor.black
        } else {
            alert.view.tintColor = UIColor.white
        }
        
        self.present(alert, animated: true, completion: {self.tableView.isEditing = false})
    }
    
    
    func showTopicAlert(aMessage: String?){
        
        if rlmSystem.first!.locationSharing {
            alertTextField?.text = ""
        } else {
            alertTextField?.text = "Topic sources require location sharing which is currently disabled"
        }
        
        let alert = UIAlertController(
            title: "Topic", message: alertTextField?.text, preferredStyle: UIAlertController.Style.alert
        )

        alert.addTextField(configurationHandler: urlConfigurationTextField)
        alert.addAction(UIAlertAction(title: "Ok",     style: UIAlertAction.Style.default, handler: handleEnterTopic))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: handleCancel))
        
        if traitCollection.userInterfaceStyle == .light {
            alert.view.tintColor = UIColor.black
        } else {
            alert.view.tintColor = UIColor.white
        }
        
        self.present(alert, animated: true, completion: {self.tableView.isEditing = false})
    }
    
    
    func showAddSourceAlert() {
        let alert = UIAlertController(
            title: nil, message: nil, preferredStyle: UIAlertController.Style.alert
        )
        
        alert.addAction(UIAlertAction(title: "Add URL",   style: UIAlertAction.Style.default, handler: { _ in self.showURLAlert(aMessage: "") } ))
        alert.addAction(UIAlertAction(title: "Add Topic", style: UIAlertAction.Style.default, handler: { _ in self.showTopicAlert(aMessage: "") } ))
        alert.addAction(UIAlertAction(title: "Cancel",    style: UIAlertAction.Style.cancel,  handler: handleCancel))
        
        if traitCollection.userInterfaceStyle == .light {
            alert.view.tintColor = UIColor.black
        } else {
            alert.view.tintColor = UIColor.white
        }
        
        self.present(alert, animated: true, completion: {self.tableView.isEditing = false})
    }
    
    
    func renameConfigurationTextField(textField: UITextField!)
    {
        if let _ = textField {
            self.alertTextField = textField!
            if selected != nil {
                self.alertTextField?.text = selected?.name
            }
        }
    }
    
 
    func shareURLAction(url: String) {
        
        let textToShare = [ url ]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        // activityViewController.excludedActivityTypes = [ UIActivityType.airDrop ]
        
        activityViewController.view.tintColor = UIColor.black
        
        self.present(activityViewController, animated: true, completion: {self.tableView.isEditing = false})
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
                if alertTextField?.text != nil {
                    // TODO: Add RLM_ObjSettings for all objects?
                }
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    
    func storeMarkerIconFilePath(feedDBItem: RLM_Feed, markerImagePath: URL, markerImageURL: String) {
        print("storeThumb")
        
        do {
            try realm.write {
                feedDBItem.customMarkerUrl = markerImageURL
                feedDBItem.customMarkerPath = markerImagePath.path
                //feedDBItem.thumbImageUrl = markerImageURL
                //feedDBItem.thumbImagePath = markerImagePath.path
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    
    func downloadCustomMarkerIcon(feedDBItem: RLM_Feed, markerURL: String) {
        print("Downloading Custom Marker Icon...")
        let allowedFormats = ["jpg", "png", "gif", "usdz", "mp3"]
        let urlExt = (markerURL as NSString).pathExtension

        if (allowedFormats.contains(urlExt.lowercased())) {
            do {
                try realm.write {
                    feedDBItem.sa = markerURL
                    feedDBItem.customMarkerUrl = markerURL
                }
            } catch {
                print("Error: \(error)")
            }
            
            let markerIconUrl   = URL(string: feedDBItem.customMarkerUrl)
            print("Setting new topic source Icon Url: " + markerURL)
            
            if (markerIconUrl != nil) {
                
                let markerIconUrl   = URL(string: feedDBItem.customMarkerUrl)
                let documentsUrl    = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
                let fileName        = feedDBItem.id + String(feedDBItem.id) + "_" + (markerIconUrl?.lastPathComponent)!
                let destinationUrl  = documentsUrl.appendingPathComponent(fileName)

                let httpDl = HttpDownloader()
                let _ = httpDl.loadFileAsync(
                    preserveFields: ["a":"b"],
                    removeExisting: true, url: markerIconUrl!, destinationUrl: destinationUrl!,
                    completion: { DispatchQueue.main.async {
                        self.storeMarkerIconFilePath(feedDBItem: feedDBItem, markerImagePath: destinationUrl!, markerImageURL: markerURL)
                        }
                    }
                )
            } else {
                print("Error setting custom topic source icon #A")
            }
        } else {
            print("Error setting custom topic source icon #B")
            
//            do {
//                try realm.write {
//                    feedDBItem.customMarkerUrl = ""
//                }
//            } catch {
//                print("Error: \(error)")
//            }
            
        }
        
    }
    
    
    func editMarkerIcon(topicSource: RLM_Feed) {
        
        let alert = UIAlertController(
            title: "Custom marker URL (PNG / JPG / GIF)", message: "", preferredStyle: UIAlertController.Style.alert
        )
        
//        alert.addTextField(configurationHandler: nil)
//        alert.textFields?.first?.backgroundColor = UIColor.clear
//        alert.textFields?.first?.text = "Topic:"
//        alert.textFields?.first?.allowsEditingTextAttributes = false
//        alert.textFields?.first?.textAlignment = .center
//        alert.textFields?.first?.isSelected = false
//        alert.textFields?.first?.isUserInteractionEnabled = false
        
        alert.addTextField(configurationHandler: urlConfigurationTextField)
        alert.textFields?.last?.isSelected = true
        alert.textFields?.last?.select(self)
        alert.textFields?.last?.text = topicSource.customMarkerUrl

        alert.addAction(UIAlertAction(
            title: "Ok",
            style: UIAlertAction.Style.default,
            handler: { _ in self.downloadCustomMarkerIcon(feedDBItem: topicSource, markerURL: (self.alertTextField?.text)!) }
        ))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel,  handler: nil ))
        
        if traitCollection.userInterfaceStyle == .light {
            alert.view.tintColor = UIColor.black
        } else {
            alert.view.tintColor = UIColor.white
        }
        
        self.present(alert, animated: true, completion: {self.tableView.isEditing = false})
    }
    
    
    func setMarkerSpreadRandom(feedDBItem: RLM_Feed, spreadAmount: Double) {
        
        do {
            try realm.write {
                if spreadAmount > 10 {
                    feedDBItem.da = 10
                } else {
                    feedDBItem.da = spreadAmount
                }
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    
    func editTopicMarkerPositionSpread(topicSource: RLM_Feed) {
        let alert = UIAlertController(
            title: "Randomize vertical position (0-10)", message: "", preferredStyle: UIAlertController.Style.alert
        )
        alert.addTextField(configurationHandler: urlConfigurationTextFieldNumPad)
        
        alert.addAction(UIAlertAction(
            title: "Ok",
            style: UIAlertAction.Style.default,
            handler: { _ in self.setMarkerSpreadRandom(feedDBItem: topicSource, spreadAmount: Double(self.alertTextFieldB?.text ?? "0")!) }
        ))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel,  handler: nil ))

        if traitCollection.userInterfaceStyle == .light {
            alert.view.tintColor = UIColor.black
        } else {
            alert.view.tintColor = UIColor.white
        }
        
        self.present(alert, animated: true, completion: {self.tableView.isEditing = false})

    }
    
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let section = indexPath.section
        
        if rlmFeeds[section].id != "" {
            selected = rlmFeeds[section]
        }
        
        //let shareAction = UITableViewRowAction(style: .normal, title: "Share") { (rowAction, indexPath) in
        let shareAction = UIContextualAction(style: .normal, title: "Share", handler: {_,_,_ in
            if self.selected?.topicKwd != "" {
                self.shareURLAction(url: "Topic: " + self.selected!.topicKwd)
            } else {
                self.shareURLAction(url: (self.selected?.sourceUrl)!)
            }
        })
        
        shareAction.backgroundColor = UIColor.black

        // let visitSourceLink = UITableViewRowAction(style: .normal, title: "Edit") { (rowAction, indexPath) in
        let visitSourceLink = UIContextualAction(style: .normal, title: "Edit", handler: {_,_,_ in
            self.openUrl(scheme: (self.selected?.sourceUrl)!)
        })
        visitSourceLink.backgroundColor = UIColor.black
        
        // let deleteAction = UITableViewRowAction(style: .normal, title: "Delete") { (rowAction, indexPath) in
        let deleteAction = UIContextualAction(style: .normal, title: "Delete", handler: {_,_,_ in
            self.removeFeed(indexP: indexPath)
        })
        deleteAction.backgroundColor = UIColor.black
        
        // let editMarkerAction = UITableViewRowAction(style: .normal, title: "Customize") { (rowAction, indexPath) in
        let setCustomMarkerAction = UIContextualAction(style: .normal, title: "Marker", handler: {_,_,_ in
            self.editMarkerIcon(topicSource: self.selected!)
        })
        setCustomMarkerAction.backgroundColor = UIColor.black
        
        let editMarkerDisplayAction = UIContextualAction(style: .normal, title: "Spread", handler: {_,_,_ in
            self.editTopicMarkerPositionSpread(topicSource: self.selected!)
        })
        editMarkerDisplayAction.backgroundColor = UIColor.black
        
        if self.selected?.topicKwd != "" {
            return UISwipeActionsConfiguration(actions: [shareAction, deleteAction, setCustomMarkerAction, editMarkerDisplayAction])
        } else {
            return UISwipeActionsConfiguration(actions: [shareAction, deleteAction])
        }

    }
    
    
    
//    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
//        let section = indexPath.section
//
//        if rlmFeeds[section].id != "" {
//            selected = rlmFeeds[section]
//        }
//
//        let shareAction = UITableViewRowAction(style: .normal, title: "Share") { (rowAction, indexPath) in
//            if self.selected?.topicKwd != "" {
//                self.shareURLAction(url: "Topic: " + self.selected!.topicKwd)
//            } else {
//                self.shareURLAction(url: (self.selected?.sourceUrl)!)
//            }
//        }
//        shareAction.backgroundColor = UIColor.black
//
//        let visitSourceLink = UITableViewRowAction(style: .normal, title: "Edit") { (rowAction, indexPath) in
//             self.openUrl(scheme: (self.selected?.sourceUrl)!)
//        }
//        visitSourceLink.backgroundColor = UIColor.black
//
//        let deleteAction = UITableViewRowAction(style: .normal, title: "Delete") { (rowAction, indexPath) in
//            self.removeFeed(indexP: indexPath)
//        }
//        deleteAction.backgroundColor = UIColor.black
//
//        let editMarkerAction = UITableViewRowAction(style: .normal, title: "Customize") { (rowAction, indexPath) in
//            self.editMarkerIcon(topicSource: self.selected!)
//        }
//        editMarkerAction.backgroundColor = UIColor.black
//
////        if selected?.topicKwd != "" {
////            return [shareAction, deleteAction, editMarkerAction]
////        } else {
////            return [shareAction, deleteAction]
////        }
//
//        return [shareAction, deleteAction]
//
//    }

    
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
        print("viewDidAppear: FeedsTVC")
        manualUpdate()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
}
