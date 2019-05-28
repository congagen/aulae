//
//  RLM_ChatMsg.swift
//  Aulae
//
//  Created by Tim Sandgren on 2019-05-27.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import Foundation
import RealmSwift


class RLM_ChatMsg: Object {
    
    @objc dynamic var sessionUUID: String = ""
    @objc dynamic var objectID: String = ""
    @objc dynamic var feedID: String = ""
    
    @objc dynamic var msgText: String = ""

}
