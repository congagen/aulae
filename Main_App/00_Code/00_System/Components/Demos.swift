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
            apiDemoFeed.id   = "Demo Source A"
            apiDemoFeed.name = "Demo Source A"
            apiDemoFeed.info = "Demo Source A"
            apiDemoFeed.active = false
            
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
            typeDemoFeed.id   = "Demo Source B"
            typeDemoFeed.name = "Demo Source B"
            typeDemoFeed.info = "Demo Source B"
            typeDemoFeed.active = false
            
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
            asciiDemo.id   = "Demo Source C"
            asciiDemo.name = "Demo Source C"
            asciiDemo.info = "Demo Source C"
            asciiDemo.active = false
            
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
    
        let itemCount = 6
        let distance: Double = 0.5
        
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
                    

                        self.realm.add(o)
                    }
                    
                }
            } catch {
                print("Error: \(error)")
            }
        }
        
    }
    
    
}
