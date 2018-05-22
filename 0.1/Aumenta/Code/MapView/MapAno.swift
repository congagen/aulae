import MapKit
import UIKit
import Foundation
import RealmSwift


class MapAno: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var name: String? = nil
    var id: String = ""
    
    override init() {
        self.coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        self.name = ""
        self.id = ""
        
        super.init()
    }
}