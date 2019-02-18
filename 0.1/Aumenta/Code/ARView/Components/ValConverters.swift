
import Foundation


class ValConverters {

    let radi: Double = 6378137
    let f_inv: Double = 298.257224


    func gps_to_ecef(latitude: Double, longitude: Double, altitude: Double) -> [Double] {
    //    # (lat, lon) in WSG-84 degrees
    //    # h in meters
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


    func ecef_to_enu(x:Double, y:Double, z:Double, latRef:Double, longRef:Double, altRef:Double) -> [Double] {
        let f = 1.0 / f_inv
        let e2 = 1.0 - (1.0 - f) * (1.0 - f)
        
        let cosLatRef = cos(latRef * .pi / 180.0)
        let sinLatRef = sin(latRef * .pi / 180.0)
        
        let cosLongRef = cos(longRef * .pi / 180.0)
        let sinLongRef = sin(longRef * .pi / 180.0)

        let cRef = 1.0 / sqrt(cosLatRef * cosLatRef + (1.0 - f) * (1.0 - f) * sinLatRef * sinLatRef)

        let x0 = (radi * cRef + altRef) * cosLatRef * cosLongRef
        let y0 = (radi * cRef + altRef) * cosLatRef * sinLongRef
        let z0 = (radi * cRef*(1-e2) + altRef) * sinLatRef
        
        let xEast = (-(x-x0) * sinLongRef) + ((y-y0) * cosLongRef)
        let yNorth = (-cosLongRef*sinLatRef*(x-x0)) - (sinLatRef*sinLongRef*(y-y0)) + (cosLatRef*(z-z0))
        let zUp = (cosLatRef*cosLongRef*(x-x0)) + (cosLatRef*sinLongRef*(y-y0)) + (sinLatRef*(z-z0))
        
        return [xEast, yNorth, zUp]
    }


    func geodetic_to_enu(lat:Double, lon:Double, h:Double, lat_ref:Double, lon_ref:Double, h_ref:Double) -> [Double] {
        let xyz = gps_to_ecef(latitude: lat, longitude: lon, altitude: h)
        let rtv = ecef_to_enu(x: xyz[0], y: xyz[1], z: xyz[2], latRef: lat_ref, longRef: lon_ref, altRef: h_ref)
        
        return rtv
    }
    
    
}
