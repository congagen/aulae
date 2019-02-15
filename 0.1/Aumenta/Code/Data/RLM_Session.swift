import RealmSwift
import Foundation


class RLM_Session: Object {

    @objc dynamic var hibernated: Bool = false
    @objc dynamic var mainUpdateInterval: Double = 5.0
    @objc dynamic var feedUpdateInterval: Double = 10

    @objc dynamic var currentLat: Double = 0.0
    @objc dynamic var currentLng: Double = 0.0
    
    @objc dynamic var debugUrl: String = "https://s3.amazonaws.com/abstra-dev/demo.json"
    
}
