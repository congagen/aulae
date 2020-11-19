//
//  DbOps.swift
//  Aulae
//
//  Created by Tim Sandgren on 2019-06-16.
//  Copyright © 2019 Tim Sandgren. All rights reserved.
//

import Foundation
import RealmSwift
import Realm


class DbOps {
    
    lazy var realm = try! Realm()
    lazy var rlmSystem: Results<RLM_SysSettings_117> = { self.realm.objects(RLM_SysSettings_117.self) }()
    lazy var rlmSession: Results<RLM_Session_117> = { self.realm.objects(RLM_Session_117.self) }()
    lazy var rlmChatSession: Results<RLM_ChatSess> = { self.realm.objects(RLM_ChatSess.self) }()
    
    lazy var rlmCamera: Results<RLM_CameraSettings> = { self.realm.objects(RLM_CameraSettings.self) }()
    lazy var rlmFeeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
    
    
    func dbGc(reset: Bool) {
        
        do {
            try realm.write {
                
                for f in rlmFeeds {
                    if f.deleted || reset {
                        realm.delete(f)
                    }
                }
                
                for o in feedObjects {
                    if o.deleted || reset {
                        realm.delete(o)
                    }
                }
                
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    
}
