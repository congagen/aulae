import RealmSwift
import Foundation


class RLM_Session: Object {

    @objc dynamic var sessionUUID: String = ""
    
    @objc dynamic var hibernated: Bool = false
    @objc dynamic var muteAudio:  Bool = false
    @objc dynamic var shouldRefreshView:  Bool = false
    
    @objc dynamic var feedErrorThreshold: Int = 10
    
    @objc dynamic var currentLat: Double = 0.0
    @objc dynamic var currentLng: Double = 0.0
    @objc dynamic var currentAlt: Double = 0.0
    
    @objc dynamic var mapUpdateInterval:  Double = 5.0
    @objc dynamic var feedUpdateInterval: Double = 20.0
    @objc dynamic var sysUpdateInterval:  Double = 20.0
    @objc dynamic var searchRadius:     Double = 1000000000

    @objc dynamic var scaleFactor:      Double = 5
    @objc dynamic var distanceScale:    Bool = true
    @objc dynamic var autoUpdate:       Bool = false
    @objc dynamic var backgroundGps:    Bool = false

    @objc dynamic var showPlaceholders: Bool = true
    
    @objc dynamic var defaultFeedUrl: String = "https://2hni7twyhl.execute-api.us-east-1.amazonaws.com/main/aulae"
    @objc dynamic var defaultFeedAPI: String = "https://2hni7twyhl.execute-api.us-east-1.amazonaws.com/main/aulae"
    @objc dynamic var feedSearchApi:  String = "https://2hni7twyhl.execute-api.us-east-1.amazonaws.com/main/aulae"
    
    @objc dynamic var apiHeaderValue: String = "VYtA9KZdQ26y4isktSKba59ME8h4WOCuajYwblvn"
    @objc dynamic var apiHeaderFeild: String = "x-api-key"
    
}
