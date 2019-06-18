import Foundation
import RealmSwift


class RLM_Feed: Object {
    
    @objc dynamic var name: String = ""
    @objc dynamic var version: Int = 123456789
    @objc dynamic var id: String = ""
    @objc dynamic var topicKwd: String = ""
    
    @objc dynamic var thumbImagePath:  String = ""
    @objc dynamic var thumbImageUrl:   String = ""
    @objc dynamic var customMarkerUrl: String = ""
    
    @objc dynamic var sourceUrl: String = ""
    @objc dynamic var apiKey: String = ""
    @objc dynamic var apiKeyValue: String = ""
    
    @objc dynamic var info: String = ""
    @objc dynamic var updatedUtx: Int = 0
    
    @objc dynamic var isUpdating: Bool = true
    @objc dynamic var active: Bool = true
    @objc dynamic var deleted: Bool = false
    @objc dynamic var errors: Int = 0

    @objc dynamic var installed: Bool = false
    
    @objc dynamic var objectCount: Int = 0
    @objc dynamic var jsonPath: String = ""
    
    @objc dynamic var lat: Double = 0
    @objc dynamic var lng: Double = 0
    
    @objc dynamic var da: Double = 0
    @objc dynamic var ba: Bool = false
    @objc dynamic var sa: String = ""
    
    @objc dynamic var db: Double = 0
    @objc dynamic var bb: Bool = false
    @objc dynamic var sb: String = ""
    
    @objc dynamic var dc: Double = 0
    @objc dynamic var bc: Bool = false
    @objc dynamic var sc: String = ""
    
    @objc dynamic var radius: Double = 1000000000
    
}
