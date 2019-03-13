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
        
        demoFeed.url  = ""
        demoFeed.id   = "Demo Feed"
        demoFeed.name = "Demo Feed"
        
        let itemCount = 4
        
        do {
            try realm.write {
                self.realm.add(demoFeed)
                
                for i in 1...itemCount {
                    let o         = RLM_Obj()
                    o.name        = String(i)
                    o.feedId      = demoFeed.id
                    o.active      = true
                    o.contentLink = "https://www.abstraqata.com/aulae"
                    
                    o.filePath    = "instro.png"
                    
                    o.style       = 0
                    o.type        = "image"
                    o.text        = "Bla"
                    
                    o.world_position = false
                    
                    o.x_pos = sin( ((Double.pi / Double(itemCount / 2)) * Double(i)) ) * Double(1)
                    o.z_pos = cos( ((Double.pi / Double(itemCount / 2)) * Double(i)) ) * Double(1)
                    o.y_pos = 0
                    
                    self.realm.add(o)
                }
                
            }
        } catch {
            print("Error: \(error)")
        }
        
    }
    
    
}
