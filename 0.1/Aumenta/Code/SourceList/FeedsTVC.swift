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

class FeedsTVC: UITableViewController {

    let realm = try! Realm()
    lazy var feeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()

    var textField: UITextField? = nil

    var selected: RLM_Feed? = nil
    
    
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
        let feed = RLM_Feed()
        
        //let date = Date()
        //let formatter = DateFormatter()
        //formatter.dateFormat = "yyyy/MM/dd - HH:mm"
        //let result = formatter.string(from: date)
        
        do {
            try realm.write {
                feed.id = UUID().uuidString
                feed.name = String("Updating...")
                
                self.realm.add(feed)
            }
        } catch {
            print("Error: \(error)")
        }
        
        selected = feed
        
        showURLAlert(aMessage: "https://...")
        
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
    }
    
    
    func handleCancel(alertView: UIAlertAction!)
    {
        print(self.textField?.text! ?? "")
    }
    
    
    func handleOk(alertView: UIAlertAction!)
    {
        do {
            try realm.write {
                if selected != nil {
                    if textField?.text != nil { selected?.name = (textField?.text)! }
                }
            }
        } catch {
            print("Error: \(error)")
        }
        
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let feed = feeds[section]

        do {
            try realm.write {
                feed.active = !feed.active
                
            }
        } catch {
            print("Error: \(error)")
        }
        
        print("didSelectRowAt")
        print(!feed.active)
        
        tableView.reloadData()
    }
    

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let feed = feeds[section]
        
        cell.textLabel?.text = String(feed.name)
        cell.detailTextLabel?.text = "Feed: " + String(feed.url)

        cell.restorationIdentifier = feed.id
        cell.backgroundColor = UIColor.clear
        cell.contentView.backgroundColor = UIColor.clear
        cell.accessibilityHint = String(feed.name) + " Feed: " + String(feed.url)
        
        if !feed.active {
            cell.textLabel?.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
            cell.detailTextLabel?.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        } else {
            cell.textLabel?.textColor = UIColor.black
            cell.detailTextLabel?.textColor = UIColor.black
        }
        
        return cell
    }
    

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func removeFeed(indexP: IndexPath) {
        
        let section = indexP.section
        let feed = feeds[section]
        
        do {
            try realm.write {
                for obj in feedObjects.filter( {$0.id == feed.id} ) {
                    obj.deleted = true
                    obj.active = false
                }
                
                feed.deleted = true
                feed.active = false
            }
        } catch {
            print("Error: \(error)")
        }
        
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
    }
    
    
    func urlConfigurationTextField(textField: UITextField!)
    {
        if let _ = textField {
            self.textField = textField!
            if selected != nil {
                textField.text! = (selected?.url)!
            }
        }
    }
    
    
    func handleEnterURL(alertView: UIAlertAction!) {
        if selected != nil {
            do {
                try realm.write {
                    if textField?.text != nil { selected?.url = (textField?.text)! }
                }
            } catch {
                print("Error: \(error)")
            }
        }
        
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
    }
    
    
    func showURLAlert(aMessage: String?){
        let alert = UIAlertController(
            title: "Feed URL",
            message: "",
            preferredStyle: UIAlertControllerStyle.alert
        )
        
        // TODO: Add Name Field
        
        alert.addTextField(configurationHandler: urlConfigurationTextField)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler:handleCancel))
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler:handleEnterURL))
        
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
    
 
    func showRenameAlert(aMessage: String?){
        let alert = UIAlertController(
            title: "",
            message: "",
            preferredStyle: UIAlertControllerStyle.alert
        )
        
        alert.addTextField(configurationHandler: renameConfigurationTextField)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler:handleCancel))
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler:handleOk))
        alert.view.tintColor = UIColor.black
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func shareURLAction(url: String) {
        
        let textToShare = [ url ]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        // activityViewController.excludedActivityTypes = [ UIActivityType.airDrop ]
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let section = indexPath.section
        
        if feeds[section].id != "" {
            selected = feeds[section]
        }
        
        let shareAction = UITableViewRowAction(style: .normal, title: "Share") { (rowAction, indexPath) in
            self.shareURLAction(url: (self.selected?.url)!)
        }
        shareAction.backgroundColor = UIColor(red: 0.0, green: 0.5, blue: 1, alpha: 0.75)
        
        let renameAction = UITableViewRowAction(style: .normal, title: "Rename") { (rowAction, indexPath) in
            self.showRenameAlert(aMessage: self.selected?.name)
        }
        renameAction.backgroundColor = UIColor(red: 0.0, green: 0.2, blue: 1, alpha: 0.75)
        
        let deleteAction = UITableViewRowAction(style: .normal, title: "Delete") { (rowAction, indexPath) in
            self.removeFeed(indexP: indexPath)
        }
        deleteAction.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.75)
        
        return [shareAction, renameAction, deleteAction]
    }

    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return screenHeight * 0.15
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
        return feeds.filter({!$0.deleted}).count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
}
