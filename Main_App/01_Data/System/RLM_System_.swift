import RealmSwift
import Foundation


class RLM_System_: Object {
    
    @objc dynamic var sessionUUID: String = ""
    
    @objc dynamic var isUpdatingFeeds: Bool = false
    @objc dynamic var isUpdatingObjects: Bool = false
    @objc dynamic var needsRefresh: Bool = false
    
}
