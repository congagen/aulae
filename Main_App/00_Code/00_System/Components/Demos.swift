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
        
        let demoSrcA = "https://2hni7twyhl.execute-api.us-east-1.amazonaws.com/main/aulae"
        let demoSrcB = "https://s3.amazonaws.com/aulae-examples/sources/images/aulae_demo.json"
        let demoSrcC = "https://2hni7twyhl.execute-api.us-east-1.amazonaws.com/main/aulae-avr"
        
        if rlmFeeds.filter({ $0.sourceUrl == demoSrcA }).count == 0 {
            let apiDemoFeed = RLM_Feed()
            apiDemoFeed.sourceUrl = demoSrcA
            apiDemoFeed.id   = "Example Source A"
            apiDemoFeed.name = "Example Source A"
            apiDemoFeed.info = "Example Source A"
            apiDemoFeed.active = true
            
            do {
                try realm.write {
                    self.realm.add(apiDemoFeed)
                }
            } catch {
                print("Error: \(error)")
            }
        }
        
        if rlmFeeds.filter({ $0.sourceUrl == demoSrcB }).count == 0 {
            let typeDemoFeed = RLM_Feed()
            typeDemoFeed.sourceUrl = demoSrcB
            typeDemoFeed.id   = "Example Source B"
            typeDemoFeed.name = "Example Source B"
            typeDemoFeed.info = "Example Source B"
            typeDemoFeed.active = true
            
            do {
                try realm.write {
                    self.realm.add(typeDemoFeed)
                }
            } catch {
                print("Error: \(error)")
            }
        }
        
        if rlmFeeds.filter({ $0.sourceUrl == demoSrcC }).count == 0 {
            let asciiDemo = RLM_Feed()
            asciiDemo.sourceUrl = demoSrcC
            asciiDemo.id   = "Example Source C"
            asciiDemo.name = "Example Source C"
            asciiDemo.info = "Example Source C"
            asciiDemo.active = true
            
            do {
                try realm.write {
                    self.realm.add(asciiDemo)
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    
    func quickStartExamples() {
        let demoFeed = RLM_Feed()
        
        demoFeed.sourceUrl = ""
        demoFeed.id   = "Quickstart"
        demoFeed.name = "Getting Started"
        demoFeed.info = "Interface guide"
    
        let itemCount = 4
        let distance: Double = 1
        
        if rlmFeeds.filter({ $0.id == demoFeed.id && $0.info == demoFeed.info }).count == 0 {
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
                        
                        if i == 3 {
                            o.filePath   = "Guide.png"
                            o.x_pos      = -distance
                            o.z_pos      = 0
                        }
                        
                        if i == 4 {
                            o.filePath   = "Guide.png"
                            o.x_pos      = distance
                            o.z_pos      = 0
                        }
                    
                        o.active = false
                        self.realm.add(o)
                    }
                    
                }
            } catch {
                print("Error: \(error)")
            }
        }
        
    }
    
    
}
