
import Foundation
import SceneKit
import ARKit
import CoreLocation




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
    
    
    func rotatePoint(target: CGPoint, aroundOrigin origin: CGPoint, byDegrees: CGFloat) -> CGPoint {
        let dx = target.x - origin.x
        let dy = target.y - origin.y
        let radius = sqrt(dx * dx + dy * dy)
        let azimuth = atan2(dy, dx)
        let newAzimuth = azimuth + byDegrees * CGFloat(.pi / 180.0)
        let x = origin.x + radius * cos(newAzimuth)
        let y = origin.y + radius * sin(newAzimuth)
        
        return CGPoint(x: x, y: y)
    }
    
    
    func rotateLatLong(lat: Double, lon: Double, angle: Double, center: CGPoint) -> CGPoint {
        
        let a = Double(center.x) + (cos(deg2rad(angle)))
        let b = Double(center.y) + (sin(deg2rad(angle)))
        
        let aa = Double(lat - Double(center.x)) - sin(deg2rad(angle))
        let bb = Double(lat - Double(center.x)) - cos(deg2rad(angle))
        
        let latR = a * aa * (lon - Double(center.y))
        let lonR = b * bb * (lon - Double(center.y))
        
        return CGPoint(x: latR, y: lonR)
    }
    
    
    func cclBearing(point1 : CLLocation, point2 : CLLocation) -> Double {
        let x = point1.coordinate.longitude - point2.coordinate.longitude
        let y = point1.coordinate.latitude  - point2.coordinate.latitude
        
        return fmod(rad2deg(radians: atan2(y, x)), 360.0) + 90.0
    }
    
    
    func locationWithBearing(bearing:Double, distanceMeters:Double, origin:CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let distRadians = distanceMeters / (6372797.6)
        
        let lat1 = origin.latitude  * Double.pi / 180.0
        let lon1 = origin.longitude * Double.pi / 180.0
        
        let lat2 = asin(sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(bearing))
        let lon2 = lon1 + atan2(sin(bearing) * sin(distRadians) * cos(lat1), cos(distRadians) - sin(lat1) * sin(lat2))
        
        return CLLocationCoordinate2D(latitude: lat2 * 180 / Double.pi, longitude: lon2 * 180 / Double.pi)
    }
    
    
    static func translationMatrix_b(with matrix: matrix_float4x4, for translation : vector_float4) -> matrix_float4x4 {
        var matrix = matrix
        matrix.columns.3 = translation
        return matrix
    }
    
    
    static func rotateAroundY_b(with matrix: matrix_float4x4, for degrees: Float) -> matrix_float4x4 {
        var matrix : matrix_float4x4 = matrix
        
        matrix.columns.0.x = cos(degrees)
        matrix.columns.0.z = -sin(degrees)
        
        matrix.columns.2.x = sin(degrees)
        matrix.columns.2.z = cos(degrees)
        return matrix.inverse
    }
    
    
    static func transformMatrix(for matrix: simd_float4x4, originLocation: CLLocation, location: CLLocation) -> simd_float4x4 {
        let distance = Float(location.distance(from: originLocation))
        let bearing = originLocation.bearingToLocationRadian(location)
        let position = vector_float4(0.0, 0.0, -distance, 0.0)
        let translationMatrix = translationMatrix_b(with: matrix_identity_float4x4, for: position)
        let rotationMatrix = rotateAroundY_b(with: matrix_identity_float4x4, for: Float(bearing))
        let transformMatrix = simd_mul(rotationMatrix, translationMatrix)
        return simd_mul(matrix, transformMatrix)
    }
    
    
    func makeARAnchor(from location: CLLocation, to landmark: CLLocation, furthestAnchorDistance: Float) -> ARAnchor {
        
        // Calculate the displacement
        let distance = location.distance(from: landmark)
        let distanceTransform = simd_float4x4.translatingIdentity(x: 0, y: 0, z: -min(Float(distance), furthestAnchorDistance))
        
        // Calculate the horizontal rotation
        let rotation = Matrix.angle(from: location, to: landmark)
        
        // Calculate the vertical tilt
        let tilt = Matrix.angleOffHorizon(from: location, to: landmark)
        
        // Apply the transformations
        let tiltedTransformation = Matrix.rotateVertically(matrix: distanceTransform, around: tilt)
        let completedTransformation = Matrix.rotateHorizontally(matrix: tiltedTransformation, around: -rotation)
        
        return ARAnchor(transform: completedTransformation)
    }
    
    
    func transformLatLong(from location: CLLocation, to landmark: CLLocation, furthestAnchorDistance: Float) -> simd_float4x4 {
        
        // Calculate the displacement
        let distance = location.distance(from: landmark)
        let distanceTransform = simd_float4x4.translatingIdentity(x: 0, y: 0, z: -min(Float(distance), 1))
        
        // Calculate the horizontal rotation
        let rotation = Matrix.angle(from: location, to: landmark)
        
        // Calculate the vertical tilt
        let tilt = Matrix.angleOffHorizon(from: location, to: landmark)
        
        // Apply the transformations
        let tiltedTransformation = Matrix.rotateVertically(matrix: distanceTransform, around: tilt)
        let completedTransformation = Matrix.rotateHorizontally(matrix: tiltedTransformation, around: -rotation)
        
        return completedTransformation
    }
    
    
    
    func cameraHeading(camera: ARCamera) -> Float {
        let deviceRotationMatrix: GLKMatrix3    = GLKMatrix4GetMatrix3(SCNMatrix4ToGLKMatrix4(SCNMatrix4.init(camera.transform)))
        let Q: GLKQuaternion = GLKQuaternionMakeWithMatrix3(deviceRotationMatrix);
        let deviceZNormal: GLKVector3 = GLKQuaternionRotateVector3(Q, GLKVector3Make(0, 0, 1));
        let deviceYNormal: GLKVector3 = GLKQuaternionRotateVector3(Q, GLKVector3Make(1, 0, 0));
        
        var zHeading: Float = atan2f(deviceZNormal.x, deviceZNormal.z);
        let yHeading: Float = atan2f(deviceYNormal.x, deviceYNormal.z);
        let isDownTilt: Bool = deviceYNormal.y > 0.0
        
        if (isDownTilt) {
            zHeading = zHeading + .pi;
            if (zHeading > .pi) {
                zHeading -= 2.0 * .pi;
            }
        }
        
        let a: Float = fabs(camera.eulerAngles.x / .pi);
        let heading: Float = a * yHeading + (1.0 - a) * zHeading;
        
        return heading
    }
    
    
    func eulerToQuaternion_b(yaw: Double, pitch: Double, roll: Double) -> SCNQuaternion {
        var result = SCNQuaternion()
        
        let cy: Double = cos(yaw   * 0.5);
        let sy: Double = sin(yaw   * 0.5);
        let cp: Double = cos(pitch * 0.5);
        let sp: Double = sin(pitch * 0.5);
        let cr: Double = cos(roll  * 0.5);
        let sr: Double = sin(roll  * 0.5);

        result.w = Float(cy * cp * cr + sy * sp * sr)
        result.x = Float(cy * cp * sr - sy * sp * cr)
        result.y = Float(sy * cp * sr + cy * sp * cr)
        result.z = Float(sy * cp * cr - cy * sp * sr)
        
        return result
    }
    
    
    func eulerToQuaternion(yaw: Double, pitch: Double, roll: Double) -> SCNQuaternion {
        
        let yawOver2 = yaw * 0.5
        let cosYawOver2 = cos(yawOver2)
        let sinYawOver2 = sin(yawOver2)
        let pitchOver2 = pitch * 0.5
        let cosPitchOver2 = cos(pitchOver2)
        let sinPitchOver2 = sin(pitchOver2)
        let rollOver2 = roll * 0.5
        let cosRollOver2 = cos(rollOver2)
        let sinRollOver2 = sin(rollOver2)
        
        var result: SCNQuaternion = SCNQuaternion()
        
        result.w = Float(cosYawOver2 * cosPitchOver2 * cosRollOver2 + sinYawOver2 * sinPitchOver2 * sinRollOver2)
        result.x = Float(sinYawOver2 * cosPitchOver2 * cosRollOver2 + cosYawOver2 * sinPitchOver2 * sinRollOver2)
        result.y = Float(cosYawOver2 * sinPitchOver2 * cosRollOver2 - sinYawOver2 * cosPitchOver2 * sinRollOver2)
        result.z = Float(cosYawOver2 * cosPitchOver2 * sinRollOver2 - sinYawOver2 * sinPitchOver2 * cosRollOver2)
        
        return result
        
    }
    

    func gps_to_ecef(latitude: Double, longitude: Double, altitude: Double) -> [Double] {
        // (lat, lon) in WSG-84 degrees
        // h in meters
        
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
        let z0 = (radi * cRef * (1.0 - e2) + altRef) * sinLatRef
        
        let xEast  = (-(x-x0) * sinLongRef)   + ((y - y0) * cosLongRef)
        let yNorth = (-cosLongRef * sinLatRef * (x - x0)) - (sinLatRef * sinLongRef * (y - y0)) + (cosLatRef * (z-z0))
        let zUp    = (cosLatRef*cosLongRef    * (x - x0)) + (cosLatRef * sinLongRef * (y - y0)) + (sinLatRef * (z-z0))
        
        return [xEast, yNorth, zUp]
    }


    func geodetic_to_enu(lat:Double, lon:Double, h:Double, lat_ref:Double, lon_ref:Double, h_ref:Double) -> [Double] {
        let xyz = gps_to_ecef(latitude: lat, longitude: lon, altitude: h)
        let rtv = ecef_to_enu(x: xyz[0], y: xyz[1], z: xyz[2], latRef: lat_ref, longRef: lon_ref, altRef: h_ref)
        
        return rtv
    }
    
}
