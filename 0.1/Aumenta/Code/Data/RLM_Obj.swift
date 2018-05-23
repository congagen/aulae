import RealmSwift
import Foundation

class RLM_Obj: Object {
    
    @objc dynamic var fileName: String = ""
    @objc dynamic var info: String = ""
    @objc dynamic var id: String = ""

    @objc dynamic var path: String = ""
    
    @objc dynamic var lat: Double = 0.0
    @objc dynamic var lng: Double = 0.0
    
    @objc dynamic var x: Double = 0.0
    @objc dynamic var y: Double = 0.0
    @objc dynamic var z: Double = 0.0
    
    @objc dynamic var size: Double = 1
    
}
