import Foundation
import RealmSwift


class RLM_Source: Object {
    
    @objc dynamic var name: String = ""
    @objc dynamic var id: String = ""
    @objc dynamic var updatedUtx: Int = 1
    
    @objc dynamic var errors: Int = 1
    
    @objc dynamic var active: Bool = true
    @objc dynamic var lat: Double = 0.0
    @objc dynamic var lng: Double = 0.0

    @objc dynamic var radius: Double = 1000
    
    @objc dynamic var url: String = "https://api.myjson.com/bins/19fxoa"
    
    var sObjects = List<RLM_Obj>()


}
