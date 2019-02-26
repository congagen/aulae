import RealmSwift
import Foundation


class RLM_Session: Object {

    @objc dynamic var hibernated: Bool = false
    @objc dynamic var currentLat: Double = 0.0
    @objc dynamic var currentLng: Double = 0.0
    
    @objc dynamic var mapUpdateInterval: Double = 5.0
    @objc dynamic var feedUpdateInterval: Double = 5.0
    @objc dynamic var contentUpdateInterval: Double = 10
    @objc dynamic var searchRadius: Double = 1000000000

    @objc dynamic var scaleFactor: Double = 5
    @objc dynamic var distanceScale: Bool = true
    @objc dynamic var autoUpdate:    Bool = true
    @objc dynamic var backgroundGps: Bool = true

    @objc dynamic var showPlaceholders: Bool = false
    @objc dynamic var allowAnimation: Bool = true
    
    @objc dynamic var debugUrl: String = "https://s3.amazonaws.com/abstra-dev/demo.json"
    
}