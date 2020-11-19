//
//  RLM_SysSettings.swift
//  Aulae
//
//  Created by Tim Sandgren on 2019-06-13.
//  Copyright © 2019 Tim Sandgren. All rights reserved.
//

import RealmSwift
import Foundation


class RLM_SysSettings_117: Object {
    
    @objc dynamic var sessionUUID: String        = ""
    @objc dynamic var feedErrorThreshold: Int    = 10
    
    @objc dynamic var muteAudio: Bool            = false
    @objc dynamic var uiMode: Int                = 0
        
    @objc dynamic var mapUpdateInterval: Double  = 5.0
    @objc dynamic var feedUpdateInterval: Double = 10.0
    @objc dynamic var sysUpdateInterval: Double  = 10.0
    @objc dynamic var searchRadius: Double       = 1000000000
    
    @objc dynamic var scaleFactor: Double        = 5
    @objc dynamic var gpsContent: Bool           = false
    @objc dynamic var onlyGpsContent: Bool       = false
    @objc dynamic var gpsScaling: Bool           = true
    
    @objc dynamic var locationSharing: Bool      = true
    @objc dynamic var autoUpdate: Bool           = false
    @objc dynamic var showPlaceholders: Bool     = true
    
    @objc dynamic var topicSubApiURL:     String = "https://2hni7twyhl.execute-api.us-east-1.amazonaws.com/main/aulae"
    @objc dynamic var topicSubApiHeaderF: String = "x-api-key"
    @objc dynamic var topicSubApiHeaderV: String = "VYtA9KZdQ26y4isktSKba59ME8h4WOCuajYwblvn"
    
    @objc dynamic var defaultFeedUrl: String     = "https://2hni7twyhl.execute-api.us-east-1.amazonaws.com/main/aulae"
    @objc dynamic var sourceSearchApi: String    = "https://2hni7twyhl.execute-api.us-east-1.amazonaws.com/main/aulae"

}
