//
//  RLM_ChatSession.swift
//  Aulae
//
//  Created by Tim Sandgren on 2019-05-27.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import Foundation
import RealmSwift


class RLM_ChatSession: Object {
    
    @objc dynamic var sessionUUID: String = ""
    @objc dynamic var objectID: String = ""
    @objc dynamic var feedID: String = ""
    
    var msgList = List<RLM_ChatMsg>()
    
}
