import RealmSwift
import Foundation

class RLM_Obj: Object {
    
    @objc dynamic var name: String = ""
    @objc dynamic var id: String = ""
    @objc dynamic var info: String = ""

    @objc dynamic var fileName: String = ""
    @objc dynamic var filePath: String = ""
    @objc dynamic var absPath: String = ""

    @objc dynamic var lat: Double = 0.0
    @objc dynamic var lng: Double = 0.0
    @objc dynamic var radius: Double = 0.0
    
    @objc dynamic var xPos: Double = 0.0
    @objc dynamic var yPos: Double = 0.0
    @objc dynamic var zPos: Double = 0.0
    
    @objc dynamic var xRot: Double = 0.0
    @objc dynamic var yRot: Double = 0.0
    @objc dynamic var zRot: Double = 0.0
    
    @objc dynamic var size: Double = 1
    
}
