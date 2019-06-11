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
        apiDemoFeed.sourceUrl = "https://2hni7twyhl.execute-api.us-east-1.amazonaws.com/main/aulae"
        apiDemoFeed.id   = "Demo Source A"
        apiDemoFeed.name = "Demo Source A"
        apiDemoFeed.info = "Demo Source A"
        apiDemoFeed.active = false
        
        let typeDemoFeed = RLM_Feed()
        typeDemoFeed.sourceUrl = "https://s3.amazonaws.com/aulae-examples/sources/images/aulae_demo.json"
        typeDemoFeed.id   = "Demo Source B"
        typeDemoFeed.name = "Demo Source B"
        typeDemoFeed.info = "Demo Source B"
        typeDemoFeed.active = false
        
        let asciiDemo = RLM_Feed()
        asciiDemo.sourceUrl = "https://2hni7twyhl.execute-api.us-east-1.amazonaws.com/main/aulae-avr"
        asciiDemo.id   = "Demo Source C"
        asciiDemo.name = "Demo Source C"
        asciiDemo.info = "Demo Source C"
        asciiDemo.active = false
        
        do {
            try realm.write {
                self.realm.add(apiDemoFeed)
                self.realm.add(typeDemoFeed)
                self.realm.add(asciiDemo)
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
        let distance: Double = 0.5
        
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
                        o.filePath   = "Guide.png"
                        o.x_pos      = 0
                        o.z_pos      = -distance
                    }
                    
                    if i == 2 {
                        o.filePath   = "Guide.png"
                        o.x_pos      = 0
                        o.z_pos      = distance
                    }
                

                    self.realm.add(o)
                }
                
            }
        } catch {
            print("Error: \(error)")
        }
        
    }
    
    
}
