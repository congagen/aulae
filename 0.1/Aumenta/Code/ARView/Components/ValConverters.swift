
import Foundation
import SceneKit
import ARKit

class ValConverters {

    let radi: Double = 6378137
    let f_inv: Double = 298.257224
    
    
    func deg2rad(_ number: Double) -> Double {
        return number * (.pi / 180.0)
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


extension SCNNode {
    
    /// The local unit Y axis (0, 1, 0) in parent space.
    var parentUp: SCNVector3 {
        
        let transform = self.transform
        return SCNVector3(transform.m21, transform.m22, transform.m23)
    }
    
    /// The local unit X axis (1, 0, 0) in parent space.
    var parentRight: SCNVector3 {
        
        let transform = self.transform
        return SCNVector3(transform.m11, transform.m12, transform.m13)
    }
    
    /// The local unit -Z axis (0, 0, -1) in parent space.
    var parentFront: SCNVector3 {
        
        let transform = self.transform
        return SCNVector3(-transform.m31, -transform.m32, -transform.m33)
    }
}

extension GLKQuaternion {
    
    init(vector: GLKVector3, scalar: Float) {
        
        let glkVector = GLKVector3Make(vector.x, vector.y, vector.z)
        
        self = GLKQuaternionMakeWithVector3(glkVector, scalar)
    }
    
    init(angle: Float, axis: GLKVector3) {
        
        self = GLKQuaternionMakeWithAngleAndAxis(angle, axis.x, axis.y, axis.z)
    }
    
    func normalized() -> GLKQuaternion {
        
        return GLKQuaternionNormalize(self)
    }
    
    static var identity: GLKQuaternion {
        
        return GLKQuaternionIdentity
    }
}

func * (left: GLKQuaternion, right: GLKQuaternion) -> GLKQuaternion {
    
    return GLKQuaternionMultiply(left, right)
}

extension SCNQuaternion {
    
    init(_ quaternion: GLKQuaternion) {
        
        self = SCNVector4(quaternion.x, quaternion.y, quaternion.z, quaternion.w)
    }
}

extension GLKQuaternion {
    
    init(_ quaternion: SCNQuaternion) {
        
        self = GLKQuaternionMake(quaternion.x, quaternion.y, quaternion.z, quaternion.w)
    }
}

extension GLKVector3 {
    
    init(_ vector: SCNVector3) {
        self = SCNVector3ToGLKVector3(vector)
    }
}
