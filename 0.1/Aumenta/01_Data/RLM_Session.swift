import RealmSwift
import Foundation


class RLM_Session: Object {

    @objc dynamic var hibernated: Bool = false
    @objc dynamic var currentLat: Double = 0.0
    @objc dynamic var currentLng: Double = 0.0
    
    @objc dynamic var feedUpdateSpeed: Double = 5.0
    @objc dynamic var contentUpdateSpeed: Double = 10
    @objc dynamic var searchRadius: Double = 1000

    @objc dynamic var distanceScale: Bool = true
    @objc dynamic var autoUpdate:    Bool = true
    @objc dynamic var backgroundGps: Bool = true

    @objc dynamic var showPlaceholders: Bool = false
    @objc dynamic var allowAnimation: Bool = true
    
    @objc dynamic var debugUrl: String = "https://s3.amazonaws.com/abstra-dev/demo.json"
    
}
