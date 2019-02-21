
import Foundation
import SceneKit
import ARKit
import CoreLocation


extension SCNVector3 {
    
    func distance(to anotherVector: SCNVector3) -> Float {
        return sqrt(pow(anotherVector.x - x, 2) + pow(anotherVector.z - z, 2))
    }
    
    static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
        return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
}


extension CLLocation {
    
    func deg2rad(_ number: Double) -> Double {
        return number * Double.pi / 180.0
    }
    
    func rad2deg(radians: Double) -> Double {
        return radians * 180.0 / Double.pi
    }
    
    func bearingToLocationRadian(_ destinationLocation: CLLocation) -> Double {
        
        let lat1 = deg2rad(self.coordinate.latitude)
        let lon1 = deg2rad(self.coordinate.longitude)
        
        let lat2 = deg2rad(destinationLocation.coordinate.latitude)
        let lon2 = deg2rad(destinationLocation.coordinate.longitude)
        
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2);
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
        let radiansBearing = atan2(y, x)
        return radiansBearing
    }
}


class ValConverters {

    let radi: Double = 6378137
    let f_inv: Double = 298.257224
    
    func deg2rad(_ number: Double) -> Double {
        return number * Double.pi / 180.0
    }
    
    func rad2deg(radians: Double) -> Double {
        return radians * 180.0 / Double.pi
    }
    
    
    func gps_to_ecef(latitude: Double, longitude: Double, altitude: Double) -> [Double] {
        let f = 1.0 / f_inv
        
        let cosLat  = cos(latitude  * Double.pi / 180.0)
        let sinLat  = sin(latitude  * Double.pi / 180.0)

        let cosLong = cos(longitude * Double.pi / 180.0)
        let sinLong = sin(longitude * Double.pi / 180.0)

        let c: Double = 1.0 / (cosLat * cosLat + (1.0 - f) * (1.0 - f) * sinLat * sinLat).squareRoot()
        let s: Double = (1.0 - f) * (1.0 - f) * c

        let x = ((radi * c) + altitude) * cosLat * cosLong
        let y = ((radi * c) + altitude) * cosLat * sinLong
        let z = ((radi * s) + altitude) * sinLat
        
        return [x, y, z]
    }

    
}
