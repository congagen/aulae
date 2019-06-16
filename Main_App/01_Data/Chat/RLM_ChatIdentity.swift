//
//  RLM_ChatIdentity.swift
//  Aulae
//
//  Created by Tim Sandgren on 2019-06-15.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import Foundation
import RealmSwift


class RLM_ChatIdentity: Object {
    
    @objc dynamic var usernameAulae: String = ""
    @objc dynamic var password: String = ""

    @objc dynamic var bio: String = ""
    
    @objc dynamic var usernameFacebook: String = ""
    @objc dynamic var usernameWeChat: String = ""
    @objc dynamic var usernameInstagram: String = ""
    @objc dynamic var usernameTelegram: String = ""
    @objc dynamic var usernameSignal: String = ""
    @objc dynamic var usernameSlack: String = ""
    
}
