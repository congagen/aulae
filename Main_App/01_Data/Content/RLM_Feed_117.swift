//
//  RLM_Feed_117.swift
//  Aulae
//
//  Created by Tim Sandgren on 2019-07-05.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import Foundation
import RealmSwift


class RLM_Feed_117: Object {
    
    @objc dynamic var name: String = ""
    @objc dynamic var version: Int = 123456789
    @objc dynamic var id: String = ""
    @objc dynamic var topicKwd: String = ""
    
    @objc dynamic var thumbImageUrl:   String = ""
    @objc dynamic var thumbImagePath:  String = ""

    @objc dynamic var customMarkerUrl: String = ""
    @objc dynamic var customMarkerPath: String = ""
    
    @objc dynamic var feedUrl: String = ""
    @objc dynamic var chatURL:   String = ""
    @objc dynamic var miscUrlA:  String = ""
    @objc dynamic var miscUrlB:  String = ""
    
    @objc dynamic var apiKey: String = ""
    @objc dynamic var apiKeyValue: String = ""
    
    @objc dynamic var info: String = ""
    @objc dynamic var updatedUtx: Int = 0
    @objc dynamic var isUpdating: Bool = true
    @objc dynamic var active: Bool  = true
    @objc dynamic var deleted: Bool = false
    @objc dynamic var errors: Int   = 0
    
    @objc dynamic var installed: Bool = false
    
    @objc dynamic var objectCount: Int = 0
    @objc dynamic var jsonPath: String = ""
    
    @objc dynamic var lat: Double = 0
    @objc dynamic var lng: Double = 0
    
    @objc dynamic var da: Double = 0
    @objc dynamic var db: Double = 0
    @objc dynamic var dc: Double = 0
    
    @objc dynamic var ba: Bool = false
    @objc dynamic var bb: Bool = false
    @objc dynamic var bc: Bool = false
    
    @objc dynamic var sa: String = ""
    @objc dynamic var sb: String = ""
    @objc dynamic var sc: String = ""
    
    @objc dynamic var radius: Double = 1000000000
    
}

