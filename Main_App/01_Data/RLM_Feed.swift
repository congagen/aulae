import Foundation
import RealmSwift


class RLM_Feed: Object {
    
    @objc dynamic var name: String = ""
    @objc dynamic var version: Int = 123456789
    @objc dynamic var id: String = ""
    @objc dynamic var topicKwd: String = ""
    
    @objc dynamic var thumbImagePath: String = ""
    @objc dynamic var thumbImageUrl: String = ""
    
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
    
    @objc dynamic var radius: Double = 1000000000
    
    @objc dynamic var url: String = "https://2hni7twyhl.execute-api.us-east-1.amazonaws.com/dev"
    
}
