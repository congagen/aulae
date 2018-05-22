import MapKit
import UIKit
import Foundation
import RealmSwift


class MapAno: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    let name: String?
    let id: String
    
    var title = ""
    
    init() {
        super.init()
    }
    
}
