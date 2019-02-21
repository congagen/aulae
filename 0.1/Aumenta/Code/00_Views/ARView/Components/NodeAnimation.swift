//
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
    
    func animateNode(node: SCNNode){
        let moveUp = SCNAction.moveBy(x: 0, y: 1, z: 0, duration: 1)
        moveUp.timingMode = .easeInEaseOut;
        
        let moveDown = SCNAction.moveBy(x: 0, y: -1, z: 0, duration: 1)
        moveDown.timingMode = .easeInEaseOut;
        
        let moveSequence = SCNAction.sequence([moveUp, moveDown])
        let moveLoop = SCNAction.repeatForever(moveSequence)
        
        node.runAction(moveLoop)
    }

}
