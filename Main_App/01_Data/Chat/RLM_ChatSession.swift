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
    
    @objc dynamic var speakText: String = ""

    @objc dynamic var apiUrl: String = ""
    @objc dynamic var rawConversationString: String = ""
    
    @objc dynamic var agentName: String = ""
    @objc dynamic var agentId: String = ""
    @objc dynamic var agentInfo: String = ""
    @objc dynamic var agentMiscA: String = ""
    @objc dynamic var agentMiscB: String = ""
    @objc dynamic var agentMiscC: String = ""
    @objc dynamic var agentMiscD: String = ""
    
    @objc dynamic var a: String = ""
    @objc dynamic var b: String = ""
    @objc dynamic var c: String = ""
    @objc dynamic var d: String = ""

    var msgList = List<RLM_ChatMsg>()
    
}
