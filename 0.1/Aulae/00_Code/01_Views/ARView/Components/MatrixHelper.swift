import Foundation
import CoreLocation
//import GLKit
import ARKit



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


class MatrixHelper {
    
    static func translationMatrix(with matrix: matrix_float4x4, for translation : vector_float4) -> matrix_float4x4 {
        var matrix = matrix
        matrix.columns.3 = translation
        return matrix
    }
    
    static func rotateAroundY(with matrix: matrix_float4x4, for degrees: Float) -> matrix_float4x4 {
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
        let translationMatrix = MatrixHelper.translationMatrix(with: matrix_identity_float4x4, for: position)
        let rotationMatrix = MatrixHelper.rotateAroundY(with: matrix_identity_float4x4, for: Float(bearing))
        let transformMatrix = simd_mul(rotationMatrix, translationMatrix)
        return simd_mul(matrix, transformMatrix)
    }
}
