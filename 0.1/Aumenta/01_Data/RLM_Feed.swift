import Foundation
import RealmSwift


class RLM_Feed: Object {
    
    @objc dynamic var active: Bool = true
    @objc dynamic var deleted: Bool = false
    
    @objc dynamic var installed: Bool = false

    @objc dynamic var name: String = ""
    @objc dynamic var id: String = ""
    
    @objc dynamic var info: String = ""
    @objc dynamic var version: Int = 123456789
    @objc dynamic var updatedUtx: Int = 0
    
    @objc dynamic var objectCount: Int = 0
    @objc dynamic var errors: Int = 0
    @objc dynamic var jsonPath: String = ""
    
    @objc dynamic var lat: Double = 0
    @objc dynamic var lng: Double = 0
    
    @objc dynamic var radius: Double = 1000
    
    @objc dynamic var url: String = "https://s3.amazonaws.com/abstra-dev/demo.json"
    
}