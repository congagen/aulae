//
//  RLM_ChatMessage.swift
//  Aulae
//
//  Created by Tim Sandgren on 2019-06-06.
//  Copyright © 2019 Tim Sandgren. All rights reserved.
//

import Foundation


import Foundation
import RealmSwift


class RLM_ChatMessage: Object {
    
    @objc dynamic var apiId: String = ""
    @objc dynamic var indexPos: Int = 0

//    @objc dynamic var sessionUUID: String = ""
//    @objc dynamic var objectID: String = ""
//    @objc dynamic var feedID: String = ""
    
    @objc dynamic var isIncomming: Bool = false
    @objc dynamic var msgText: String = ""
    
}
