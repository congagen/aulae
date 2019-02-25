//
//  FeedActions.swift
//  Aumenta
//
//  Created by Tim Sandgren on 2019-02-25.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import Foundation
import Realm
import RealmSwift
import Foundation
    

class FeedActions{
    let realm = try! Realm()
    lazy var session: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var feeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
    
    
    
    func addFeed(item: RLM_Feed, refreshExisting: Bool) {
        
    }
    
    
    func deleteFeed(feedId: String, deleteFeedObject: Bool) {
        
    }
    
    
    
    
    
    
    
}
