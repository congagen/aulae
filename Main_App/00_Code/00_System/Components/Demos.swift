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
    
    func buildTextDemo() {
        let demoFeed = RLM_Feed()
        
        demoFeed.sourceUrl = ""
        demoFeed.id   = "User Guide"
        demoFeed.name = "Getting Started"
        demoFeed.info = "Quick Start Instructions"

        let itemCount = 4
        let distance: Double = 1.2
        
        do {
            try realm.write {
                self.realm.add(demoFeed)
                
                for i in 1...itemCount {
                    let o         = RLM_Obj()
                    o.name        = String(i)
                    o.feedId      = demoFeed.id
                    o.y_pos       = 0
                    o.demo        = true
                    
                    o.active      = true
                    o.contentLink = "https://www.abstraqata.com/aulae"
                    
                    if i == 1 {
                        o.filePath    = "welc.png"
                        o.x_pos = 0
                        o.z_pos = -distance
                    }
                    
                    if i == 2 {
                        o.filePath    = "view.png"
                        o.x_pos = distance
                        o.z_pos = -distance
                    }
                    
                    if i == 3 {
                        o.filePath    = "lib.png"
                        o.x_pos = -distance
                        o.z_pos = -distance
                    }
                    
//                    if i == 4 {
//                        o.filePath    = "map.png"
//                        o.x_pos = 0
//                        o.y_pos = distance
//                        o.z_pos = -distance
//                    }
                    
                    o.style       = 0
                    o.type        = "image"
                    o.text        = "Bla"
                    
                    o.world_position = false
                    
                    self.realm.add(o)
                }
                
            }
        } catch {
            print("Error: \(error)")
        }
        
    }
    
    
}
