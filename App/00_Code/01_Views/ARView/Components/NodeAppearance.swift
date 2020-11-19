//  NodeAnimation.swift
//  aulae
//
//  Created by Tim Sandgren on 2019-02-20.
//  Copyright © 2019 Tim Sandgren. All rights reserved.
//

import Foundation
import SceneKit
import ARKit
import CoreLocation


extension UIColor {
    
    convenience init(hexColor: String) {
        let scannHex = Scanner(string: hexColor)
        var rgbValue: UInt64 = 0
        //scannHex.scanLocation = 0
        
        scannHex.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(
            red:   CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue:  CGFloat(b) / 0xff, alpha: 1
        )
    }
}


extension ARViewer {
    
    func getNodeWorldPosition(objectDistance: Double, baseOffset: Double, contentObj: RLM_Obj, scaleFactor: Double) -> SCNVector3 {
        print("getNodeWorldPosition")
        
        let rawObjectGpsCCL      = CLLocation(latitude: contentObj.lat, longitude: contentObj.lng)
        let scaleDivider: Double = (objectDistance / scaleFactor)
        
        let translation      = MatrixHelper.transformMatrix(for: matrix_identity_float4x4, originLocation: rawDeviceGpsCCL, location: rawObjectGpsCCL)
        let translationSCNV  = SCNVector3.positionFromTransform(translation)
        
        var xPos: Double = 0
        var zPos: Double = 0
        
        if translationSCNV.x < 0 {
            xPos = Double(Double(translationSCNV.x) / scaleDivider) - baseOffset
        } else {
            xPos = Double(Double(translationSCNV.x) / scaleDivider) + baseOffset
        }
        
        if translationSCNV.z < 0 {
            zPos = Double(Double(translationSCNV.z) / scaleDivider) - baseOffset
        } else {
            zPos = Double(Double(translationSCNV.z) / scaleDivider) + baseOffset
        }
        
        var worldYPos: Double = 0
        
        if Int(contentObj.alt) != 0 && Int(rlmSession.first!.currentAlt) != 0 {
            let diff = abs(contentObj.alt - rlmSession.first!.currentAlt)
            
            if contentObj.alt < rlmSession.first!.currentAlt {
                worldYPos = -(diff * 0.05)
            } else {
                worldYPos =  (diff * 0.05)
            }
        }
        
        print("worldYPos: " + String(worldYPos))
        print(contentObj.alt)
        
        return SCNVector3(xPos, worldYPos, zPos)
    }
    
    
    func addHooverAnimation(node: SCNNode, distance: CGFloat, speed: CGFloat){
        let moveUp   = SCNAction.moveBy(x: 0, y: distance, z: 0, duration: TimeInterval(1/speed))
        moveUp.timingMode = .easeInEaseOut;
        
        let moveDown = SCNAction.moveBy(x: 0, y: -distance, z: 0, duration: TimeInterval(1/speed))
        moveDown.timingMode = .easeInEaseOut;
        
        let moveSequence = SCNAction.sequence([moveUp, moveDown])
        let moveLoop = SCNAction.repeatForever(moveSequence)
        
        node.runAction(moveLoop)
    }
    
    
    func rotateAnimation(node: SCNNode, xAmt: Float, yAmt: Float, zAmt: Float, speed: Double) {
        
        let spin = CABasicAnimation(keyPath: "rotation")
        spin.fromValue = NSValue(scnVector4: SCNVector4(x: xAmt, y: yAmt, z: zAmt, w: 0))
        spin.toValue   = NSValue(scnVector4: SCNVector4(x: xAmt, y: yAmt, z: zAmt, w: 2 * Float(Double.pi)) )
        
        spin.duration  = 1 / speed
        spin.repeatCount = .infinity
        node.addAnimation(spin, forKey: "spin around")
        
    }
    

}
