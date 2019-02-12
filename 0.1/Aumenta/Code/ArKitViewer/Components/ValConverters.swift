
// https://stackoverflow.com/questions/18759601/converting-lla-to-xyz

import Foundation


class ValConverters {

    let R: Double = 6378137
    let f_inv: Double = 298.257224


    let exampleCoords = [
        [0,  45,  1000],
        [45,  90,  2000],
        [48.8567,  2.3508,  80],
        [61.4140105652, 23.7281341313,149.821],
    ]


    func namegps_to_ecef_pyproj(lat:Double, lon:Double, alt:Double) -> [Double] {
    //    ecef = pyproj.Proj(proj='geocent', ellps='WGS84', datum='WGS84')
    //    lla = pyproj.Proj(proj='latlong', ellps='WGS84', datum='WGS84')
    //    x, y, z = pyproj.transform(lla, ecef, lon, lat, alt, radians=False)
        return [0,0,0]
    }


    func gps_to_ecef(latitude: Double, longitude: Double, altitude: Double) -> [Double] {
    //    # (lat, lon) in WSG-84 degrees
    //    # h in meters
        let f = 1.0 / f_inv
        
        let cosLat = cos(latitude * .pi / 180)
        let sinLat = sin(latitude * .pi / 180)

        let cosLong = cos(longitude * .pi / 180)
        let sinLong = sin(longitude * .pi / 180)

        let c: Double = 1 / sqrt(cosLat * cosLat + (1 - f) * (1 - f) * sinLat * sinLat)
        let s: Double = (1 - f) * (1 - f) * c

        let x = (R * c + altitude) * cosLat * cosLong
        let y = (R * c + altitude) * cosLat * sinLong
        let z = (R * s + altitude) * sinLat
        
        return [x, y, z]
    }


    func ecef_to_enu(x:Double, y:Double, z:Double, latRef:Double, longRef:Double, altRef:Double) -> [Double] {
        let f = 1.0 / f_inv
        let e2 = 1 - (1 - f) * (1 - f)
        
        let cosLatRef = cos(latRef * .pi / 180)
        let sinLatRef = sin(latRef * .pi / 180)
        
        let cosLongRef = cos(longRef * .pi / 180)
        let sinLongRef = sin(longRef * .pi / 180)

        let cRef = 1 / sqrt(cosLatRef * cosLatRef + (1 - f) * (1 - f) * sinLatRef * sinLatRef)

        let x0 = (R*cRef + altRef) * cosLatRef * cosLongRef
        let y0 = (R*cRef + altRef) * cosLatRef * sinLongRef
        let z0 = (R*cRef*(1-e2) + altRef) * sinLatRef
        
        let xEast = (-(x-x0) * sinLongRef) + ((y-y0)*cosLongRef)
        let yNorth = (-cosLongRef*sinLatRef*(x-x0)) - (sinLatRef*sinLongRef*(y-y0)) + (cosLatRef*(z-z0))
        let zUp = (cosLatRef*cosLongRef*(x-x0)) + (cosLatRef*sinLongRef*(y-y0)) + (sinLatRef*(z-z0))
        
        return [xEast, yNorth, zUp]
    }


    func geodetic_to_enu(lat:Double, lon:Double, h:Double, lat_ref:Double, lon_ref:Double, h_ref:Double) -> [Double] {
        let xyz = gps_to_ecef(latitude: lat, longitude: lon, altitude: h)
        let rtv = ecef_to_enu(x: xyz[0], y: xyz[1], z: xyz[2], latRef: lat_ref, longRef: lon_ref, altRef: h_ref)
        
        return rtv
    }


    func test() {
        for co in exampleCoords {
            let xFyFzF = gps_to_ecef(latitude: co[0], longitude: co[1], altitude: co[2])
            print("ECEF: " + String(xFyFzF[0]) + " - " + String(xFyFzF[1]) + " - " + String(xFyFzF[2]) )
            let xEyNzU = ecef_to_enu(x: xFyFzF[0], y: xFyFzF[1], z: xFyFzF[2], latRef: co[0], longRef: co[1], altRef: co[2])
            print("ENU:  " + String(xEyNzU[0]) + " - " + String(xEyNzU[1]) + " - " + String(xEyNzU[2]))
        }
    }
    
    
}
