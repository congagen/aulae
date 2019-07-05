import RealmSwift
import Foundation

class RLM_Session_117: Object {

    @objc dynamic var sessionUUID: String        = ""
    
    @objc dynamic var hibernated: Bool           = false
    @objc dynamic var shouldRefreshView: Bool    = false
    
    @objc dynamic var isUpdatingFeeds: Bool      = false
    @objc dynamic var isUpdatingObjects: Bool    = false
    @objc dynamic var needsRefresh: Bool         = false
        
    @objc dynamic var currentLat: Double         = 80.0
    @objc dynamic var currentLng: Double         = 10.0
    @objc dynamic var currentAlt: Double         = 10.0
    
    
}
