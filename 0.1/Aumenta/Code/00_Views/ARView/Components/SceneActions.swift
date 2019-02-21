//
//  SceneActions.swift
//  Aumenta
//
//  Created by Tim Sandgren on 2019-02-18.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import Foundation
import ARKit


extension ARViewer {
    
    func sharePhoto() {
        let renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: [:])
        renderer.scene = sceneView.scene
        renderer.pointOfView = sceneView.pointOfView
        let snapShot = renderer.snapshot(atTime: TimeInterval(0), with: CGSize(width: 100, height: 100), antialiasingMode: .none)
        
        let imageToShare = [snapShot]
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook ]
        
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    
    func showNodeInfo(node:SCNNode) {
        // TODO
    }
    
    

}
