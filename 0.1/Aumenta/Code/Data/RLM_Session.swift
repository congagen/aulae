import Foundation
import RealmSwift


class RLM_Session: Object {

    @objc dynamic var hibernated: Bool = false
    @objc dynamic var updateInterval: Double = 5.0
    @objc dynamic var lat: Double = 0.0

}
