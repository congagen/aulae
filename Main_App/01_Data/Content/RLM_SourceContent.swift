//
//  RLM_SourceContent.swift
//  Aulae
//
//  Created by Tim Sandgren on 2019-06-16.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import Foundation
import RealmSwift


class RLM_SourceContent: Object {
    
    @objc dynamic var title: String           = ""
    @objc dynamic var name: String            = ""
    @objc dynamic var version: Int            = 0
    
    @objc dynamic var feedId: String          = ""
    @objc dynamic var uuid: String            = ""
    @objc dynamic var info: String            = ""

    @objc dynamic var isDemoObject: Bool      = false // demo
    @objc dynamic var contentType: String     = ""    // type
    
    @objc dynamic var isActive: Bool          = true  // active
    @objc dynamic var isDeleted: Bool         = false // deleted
    @objc dynamic var isInstance: Bool        = false // instance
    
    @objc dynamic var contentUrl: String      = ""    // url
    @objc dynamic var contenFileName: String  = ""    // fileName
    @objc dynamic var contenFilePath: String  = ""    // filePath

    @objc dynamic var directLink: Bool        = false
    @objc dynamic var linkURL: String         = ""
    @objc dynamic var chatURL: String         = ""
    
    @objc dynamic var text: String            = ""
    @objc dynamic var font: String            = ""
    
    @objc dynamic var hex_color: String       = "7259ff"
    
    @objc dynamic var radius: Double          = 0
    @objc dynamic var scale: Double           = 1.0
    
    @objc dynamic var world_position: Bool    = true
    @objc dynamic var world_scale: Bool       = true
    @objc dynamic var billboard: Bool         = true
    @objc dynamic var localOrientation: Bool  = false
    
    @objc dynamic var latitude: Double        = 0 // lat
    @objc dynamic var longitude: Double       = 0 // lng
    @objc dynamic var altitude: Double        = 0 // alt
    
    @objc dynamic var xPos: Double            = 0 // x_pos
    @objc dynamic var yPos: Double            = 0 // y_pos
    @objc dynamic var zPos: Double            = 0 // z_pos
    
    @objc dynamic var style: Int              = 0
    @objc dynamic var mode: String            = "free"
    
    @objc dynamic var rotate: Double          = 0
    @objc dynamic var hoover: Double          = 0
    
}

