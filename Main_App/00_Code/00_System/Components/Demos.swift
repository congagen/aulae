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
//        let apiDemoFeed = RLM_Feed()
//        apiDemoFeed.sourceUrl = "https://2hni7twyhl.execute-api.us-east-1.amazonaws.com/dev/test"
//        apiDemoFeed.id   = "Example Source 1"
//        apiDemoFeed.name = "Example Source 1"
//        apiDemoFeed.info = "Example Source 1"
//        apiDemoFeed.active = false
//
//        let fileDemoFeed = RLM_Feed()
//        fileDemoFeed.sourceUrl = "https://s3.amazonaws.com/abstra-dev/1.json"
//        fileDemoFeed.id   = "Example Source 2"
//        fileDemoFeed.name = "Example Source 2"
//        fileDemoFeed.info = "Example Source 2"
//        fileDemoFeed.active = false
        
        let typeDemoFeed = RLM_Feed()
        typeDemoFeed.sourceUrl = "https://abstraqata.squarespace.com/s/aulae_demo.json"
        typeDemoFeed.id   = "Example Source"
        typeDemoFeed.name = "Example Source"
        typeDemoFeed.info = "Example Source"
        typeDemoFeed.active = false
        
        do {
            try realm.write {
                self.realm.add(typeDemoFeed)
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    
    func quickStartExamples() {
        let demoFeed = RLM_Feed()
        
        demoFeed.sourceUrl = ""
        demoFeed.id   = "Quickstart"
        demoFeed.name = "Getting Started"
        demoFeed.info = "Interface guide"
    
        let itemCount = 6
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
                        o.z_pos      = -distance * 2
                    }
                    
                    if i == 2 {
                        o.filePath   = "map.png"
                        o.x_pos      = -distance
                        o.z_pos      = -distance * 1.5
                    }
                    
                    if i == 3 {
                        o.filePath   = "lib.png"
                        o.x_pos      = distance
                        o.z_pos      = -distance * 1.5
                    }
                    
                    if i == 4 {
                        o.filePath   = "lib.png"
                        o.x_pos      = -distance
                        o.z_pos      = distance * 1.5
                    }
                    
                    if i == 5 {
                        o.filePath   = "view.png"
                        o.x_pos      = 0
                        o.z_pos      = distance * 1.5
                    }
                    
                    if i == 6 {
                        o.filePath   = "map.png"
                        o.x_pos      = distance
                        o.z_pos      = distance * 1.5
                    }

                    self.realm.add(o)
                }
                
            }
        } catch {
            print("Error: \(error)")
        }
        
    }
    
    
}
