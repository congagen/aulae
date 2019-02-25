//  NodeAnimation.swift
//  Aumenta
//
//  Created by Tim Sandgren on 2019-02-20.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import Foundation
import SceneKit
import ARKit


extension ARViewer {
    
    func addHooverAnimation(node: SCNNode){
        let moveUp = SCNAction.moveBy(x: 0, y: 1, z: 0, duration: 1)
        moveUp.timingMode = .easeInEaseOut;
        
        let moveDown = SCNAction.moveBy(x: 0, y: -1, z: 0, duration: 1)
        moveDown.timingMode = .easeInEaseOut;
        
        let moveSequence = SCNAction.sequence([moveUp, moveDown])
        let moveLoop = SCNAction.repeatForever(moveSequence)
        
        node.runAction(moveLoop)
    }
    
    
    func rotateAnimation(node: SCNNode, xAmt: Float, yAmt: Float, zAmt: Float){
        
        let spin = CABasicAnimation(keyPath: "rotation")
        spin.fromValue = NSValue(scnVector4: SCNVector4(x: xAmt, y: yAmt, z: zAmt, w: 0))
        spin.toValue   = NSValue(scnVector4: SCNVector4(x: xAmt, y: yAmt, z: zAmt, w: 2 * Float(Double.pi)) )
        
        spin.duration  = 3
        spin.repeatCount = .infinity
        node.addAnimation(spin, forKey: "spin around")
        
    }
    

}
