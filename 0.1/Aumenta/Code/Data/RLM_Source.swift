import Foundation
import RealmSwift


class RLM_Source: Object {
    
    
    @objc dynamic var name: String = ""
    @objc dynamic var id: String = ""
    
    @objc dynamic var active: Bool = true
    
    @objc dynamic var lat: Double = 0.0
    @objc dynamic var lng: Double = 0.0

    @objc dynamic var redius: Double = 100
    
    @objc dynamic var url: String = "https://raw.githubusercontent.com/markbrown4/webgl-workshop/master/models/stanford-bunny.dae"

}
