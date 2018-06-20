import RealmSwift
import Foundation

class RLM_Obj: Object {
    
    @objc dynamic var name: String = ""
    @objc dynamic var id: String = ""
    @objc dynamic var feedId: String = ""
    @objc dynamic var version: Int = 0
    @objc dynamic var info: String = ""
    
    @objc dynamic var url: String = ""
    
    @objc dynamic var type: String = ""
    @objc dynamic var style: Int = 0
    
    @objc dynamic var text: String = ""
    
    @objc dynamic var active: Bool = true
    @objc dynamic var deleted: Bool = false

    @objc dynamic var fileName: String = ""
    @objc dynamic var filePath: String = ""

    @objc dynamic var lat: Double = 59.292
    @objc dynamic var lng: Double = 18.102
    @objc dynamic var radius: Double = 0.0
    
    @objc dynamic var x_pos: Double = 0.0
    @objc dynamic var y_pos: Double = 0.0
    @objc dynamic var z_pos: Double = 0.0
    
    @objc dynamic var x_rot: Double = 0.0
    @objc dynamic var y_rot: Double = 0.0
    @objc dynamic var z_rot: Double = 0.0
    
    @objc dynamic var scale: Double = 1.0
    
}
