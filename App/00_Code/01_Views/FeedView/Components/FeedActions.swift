//
//  FeedActions.swift
//  aulae
//
//  Created by Tim Sandgren on 2019-02-25.
//  Copyright © 2019 Tim Sandgren. All rights reserved.
//

import Foundation
import UIKit
import Realm
import RealmSwift
import Foundation
    

class FeedActions {
    
    lazy var realm = try! Realm()    
    lazy var rlmSession: Results<RLM_Session_117> = { self.realm.objects(RLM_Session_117.self) }()
    lazy var rlmFeeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
    
    var textField: UITextField? = nil
    
    func urlConfigurationTextField(textField: UITextField!)
    {
        if let _ = textField {
            self.textField = textField!
            textField.text! = ""
        }
    }
    
    
    func addNewSource(feedUrl: String, feedApiKwd: String, refreshExisting: Bool) {
        print("addFeed")
        let newFeed = RLM_Feed()

        if refreshExisting {
            if rlmFeeds.filter( {$0.sourceUrl == feedUrl && $0.topicKwd == feedApiKwd} ).count > 0 {
                for f in rlmFeeds.filter({$0.sourceUrl == feedUrl && $0.topicKwd == feedApiKwd}) {
                    deleteFeed(feedId: f.id, deleteFeedObjects: true, deleteFeed: false)
                }
            }
        }
        
        if rlmFeeds.filter({ !$0.deleted }).filter({$0.sourceUrl == feedUrl && $0.topicKwd == feedApiKwd}).count == 0 {
            do {
                try realm.write {
                    newFeed.sourceUrl = feedUrl
                    newFeed.id = UUID().uuidString
                    
                    if newFeed.id.lowercased() != "quickstart" {
                        newFeed.name = "Updating..." // IF Topic -> Name = Topic
                    }
                    
                    newFeed.topicKwd = feedApiKwd                    
                    self.realm.add(newFeed)
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    
    func deleteFeed(feedId: String, deleteFeedObjects: Bool, deleteFeed: Bool) {
        let matchingFeeds = rlmFeeds.filter( {$0.id == feedId } )
        
        for f in matchingFeeds {
            do {
                try realm.write {
                    if (deleteFeedObjects) {
                        for obj in feedObjects.filter( {$0.feedId == f.id} ) {
                            obj.deleted = true
                            obj.active  = false
                            
                            realm.delete(obj)
                        }
                    }
                    
                    f.deleted = true
                    f.active = false

                    if deleteFeed {
                        realm.delete(f)
                    }
                    
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }

    
}
