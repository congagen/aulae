import RealmSwift
import Foundation


class RLM_Session: Object {

    @objc dynamic var hibernated: Bool = false
    @objc dynamic var updateInterval: Double = 5.0

    @objc dynamic var currentLat: Double = 0.0
    @objc dynamic var currentLng: Double = 0.0
    
    var sessionBeacons = List<RLM_ObjectPath>()

}
