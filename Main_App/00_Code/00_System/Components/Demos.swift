//
//  Demos.swift
//  Aulae
//
//  Created by Tim Sandgren on 2019-03-08.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import Foundation
import Realm
import RealmSwift


extension MainVC {
    
    
    func contentExamples() {
        let apiDemoFeed = RLM_Feed()
        apiDemoFeed.sourceUrl = "https://2hni7twyhl.execute-api.us-east-1.amazonaws.com/dev/test"
        apiDemoFeed.id   = "Api Demo"
        apiDemoFeed.name = "Api Demo"
        apiDemoFeed.info = "Api Demo"
        apiDemoFeed.active = false
        
        let fileDemoFeed = RLM_Feed()
        fileDemoFeed.sourceUrl = "https://s3.amazonaws.com/abstra-dev/1.json"
        fileDemoFeed.id   = "WWW Demo"
        fileDemoFeed.name = "WWW Demo"
        fileDemoFeed.info = "WWW Demo"
        fileDemoFeed.active = false
        
        do {
            try realm.write {
                self.realm.add(apiDemoFeed)
                self.realm.add(fileDemoFeed)
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    
    func quickStartExamples() {
        let demoFeed = RLM_Feed()
        
        demoFeed.sourceUrl = ""
        demoFeed.id   = "GettingStartedId"
        demoFeed.name = "Getting Started"
        demoFeed.info = "Quick Start Instructions"
    
        let itemCount = 4
        let distance: Double = 1.2
        
        do {
            try realm.write {
                self.realm.add(demoFeed)
                
                for i in 1...itemCount {
                    let o            = RLM_Obj()
                    
                    o.name           = String(i)
                    o.feedId         = demoFeed.id
                    o.y_pos          = 0
                    
                    o.type           = "demo"
                    o.demo           = true
                    o.world_position = false
                    o.world_scale    = false
                    o.active         = true
                    o.contentLink    = "https://www.abstraqata.com/aulae"
                    
                    if i == 1 {
                        o.filePath   = "welc.png"
                        o.x_pos      = 0
                        o.z_pos      = -distance * 1.5
                    }
                    
                    if i == 2 {
                        o.filePath   = "view.png"
                        o.x_pos      = distance
                        o.z_pos      = -distance * 1.5
                    }
                    
                    if i == 3 {
                        o.filePath   = "lib.png"
                        o.x_pos      = -distance
                        o.z_pos      = -distance * 1.5
                    }
                    
//                    if i == 4 {
//                        o.filePath   = "map.png"
//                        o.x_pos      = 0
//                        o.y_pos      = 0
//                        o.z_pos      = distance * 1.5
//                    }

                    self.realm.add(o)
                }
                
            }
        } catch {
            print("Error: \(error)")
        }
        
    }
    
    
}
