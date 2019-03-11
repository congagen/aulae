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
        
        let welcome = [
            0: [
                0: "Bla",
                1: "Bla",
                2: "Bla",
                3: "Bla"
                
            ]
        ]
        
        demoFeed.url  = ""
        demoFeed.id   = "Demo Feed"
        demoFeed.name = "Demo Feed"
        
        let itemCount = 9
        
        do {
            try realm.write {
                self.realm.add(demoFeed)
                
                for i in 1...itemCount {
                    let o = RLM_Obj()
                    o.name = String(i)
                    o.feedId = demoFeed.id
                    o.contentUrl = ""
                    o.active = true
                    
                    o.lat = 10
                    o.lng = 50
                    o.style = 0
                    o.type  = "text"
                    o.text  = "AULAE"
                    
                    o.world_position = false
                    
                    o.x_pos = sin( ((Double.pi / Double(itemCount / 2)) * Double(i)) ) * Double(itemCount)
                    o.z_pos = cos( ((Double.pi / Double(itemCount / 2)) * Double(i)) ) * Double(itemCount)
                    o.y_pos = 0
                    
                    self.realm.add(o)
                }
            }
        } catch {
            print("Error: \(error)")
        }
        
    }
    
    
}
