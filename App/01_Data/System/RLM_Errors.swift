//
//  RLM_Errors.swift
//  Aulae
//
//  Created by Tim Sandgren on 2020-07-30.
//  Copyright © 2020 Tim Sandgren. All rights reserved.
//

import RealmSwift
import Foundation


class RLM_Errors: Object {
    
    @objc dynamic var crashed: Bool = false
    @objc dynamic var crashCount: Int = 0
    
    @objc dynamic var loadErrors: Int = 0
    @objc dynamic var feedErrors: Int = 0
    
    @objc dynamic var a: Bool = false
    @objc dynamic var b: Bool = false
    @objc dynamic var c: Bool = false
    @objc dynamic var d: Bool = false
    
}
