//
//  RLM_SysSettings.swift
//  Aulae
//
//  Created by Tim Sandgren on 2019-06-13.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import RealmSwift
import Foundation


class RLM_SysSettings: Object {
    
    @objc dynamic var sessionUUID: String = ""
    
    @objc dynamic var isUpdatingFeeds: Bool = false
    @objc dynamic var isUpdatingObjects: Bool = false
    @objc dynamic var needsRefresh: Bool = false
    
    @objc dynamic var uiMode: Int = 0

}
