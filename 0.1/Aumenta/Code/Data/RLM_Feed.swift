import Foundation
import RealmSwift


class RLM_Feed: Object {
    
    @objc dynamic var active: Bool = true
    
    @objc dynamic var name: String = ""
    @objc dynamic var id: String = ""
    @objc dynamic var info: String = ""
    @objc dynamic var version: String = "123456789"
    @objc dynamic var updatedUtx: Int = 0
    
    @objc dynamic var errors: Int = 1
    
    @objc dynamic var jsonPath: String = ""
    
    @objc dynamic var lat: Double = 0.0
    @objc dynamic var lng: Double = 0.0
    
    @objc dynamic var radius: Double = 1000
    @objc dynamic var url: String = "https://api.myjson.com/bins/h61m6"
    
}
