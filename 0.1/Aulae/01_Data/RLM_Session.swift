import RealmSwift
import Foundation


class RLM_Session: Object {

    @objc dynamic var hibernated: Bool = false
    @objc dynamic var muteAudio:  Bool = true

    @objc dynamic var feedErrorThreshold: Int = 10
    
    @objc dynamic var currentLat: Double = 0.0
    @objc dynamic var currentLng: Double = 0.0
    @objc dynamic var currentAlt: Double = 0.0
    
    @objc dynamic var mapUpdateInterval: Double = 5.0
    @objc dynamic var feedUpdateInterval: Double = 5.0
    @objc dynamic var contentUpdateInterval: Double = 10
    @objc dynamic var searchRadius: Double = 1000000000

    @objc dynamic var scaleFactor:   Double = 5
    @objc dynamic var distanceScale: Bool = false
    @objc dynamic var autoUpdate:    Bool = true
    @objc dynamic var backgroundGps: Bool = false

    @objc dynamic var showPlaceholders: Bool = true
    @objc dynamic var allowAnimation:   Bool = true
    
    @objc dynamic var debugUrl: String = "https://2hni7twyhl.execute-api.us-east-1.amazonaws.com/dev"
    
}
