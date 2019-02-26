//
//  FeedActions.swift
//  Aumenta
//
//  Created by Tim Sandgren on 2019-02-25.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import Foundation
import UIKit
import Realm
import RealmSwift
import Foundation
    

class FeedActions {
    
    let realm = try! Realm()
    lazy var session: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var feeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
    
    var textField: UITextField? = nil

    
    func urlConfigurationTextField(textField: UITextField!)
    {
        if let _ = textField {
            self.textField = textField!
            textField.text! = (session.first?.debugUrl)!
        }
    }
    
    
    func showAddSearchFeedAlert(feedTitle: String, feedUrl: String?, message: String, rootView: UITableViewController){
        let alert = UIAlertController(
            title: feedTitle,
            message: message,
            preferredStyle: UIAlertController.Style.alert
        )
        
        alert.addAction(
            UIAlertAction(
                title: "Ok",
                style: UIAlertAction.Style.default,
                handler: { _ in self.addFeed(feedUrl: feedUrl!, refreshExisting: true) }
            )
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel,  handler: nil ))

        alert.view.tintColor = UIColor.black
        rootView.present(
            alert,
            animated: true,
            completion: {
                rootView.tableView.reloadData();
                rootView.reloadInputViews()
        }
        )
    }
    
    
    func addFeed(feedUrl: String, refreshExisting: Bool) {
        let newFeed = RLM_Feed()

        if refreshExisting {
            if feeds.filter({$0.url == feedUrl }).count > 0 {
                let exId = feeds.filter({$0.url == feedUrl }).first?.id
                deleteFeed(feedId: exId!, deleteFeedObjects: true)
            }
        }
        
        if feeds.filter({$0.url == feedUrl }).count == 0 {
            
            do {
                try realm.write {
                    newFeed.url  = feedUrl
                    newFeed.id   = UUID().uuidString
                    newFeed.name = "Updating..."
                    
                    self.realm.add(newFeed)
                }
            } catch {
                print("Error: \(error)")
            }
            
        }
    }
    
    
    func deleteFeed(feedId: String, deleteFeedObjects: Bool) {
        let currentFeeds = feeds.filter( {$0.id == feedId} )
        
        for f in currentFeeds {
            do {
                try realm.write {
                    if (deleteFeedObjects) {
                        for obj in feedObjects.filter( {$0.id == feedId} ) {
                            obj.deleted = true
                            obj.active = false
                        }
                    }
                    
                    f.deleted = true
                    f.active = false
                    
                    realm.delete(f)
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }

    
}
