//
//  SceneNodeUtils.swift
//  Aumenta
//
//  Created by Tim Sandgren on 2019-02-18.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import UIKit
import SceneKit
import Foundation
import ARKit


extension ARViewer {
    
    
    func createGIFAnimation(url:URL, fDuration:Float) -> CAKeyframeAnimation? {
        
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let frameCount = CGImageSourceGetCount(src)
        
        var time : Float = 0
        
        var framesArray = [AnyObject]()
        var tempTimesArray = [NSNumber]()
        
        for i in 0..<frameCount {
            
            var frameDuration : Float = fDuration;
            
            let cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(src, i, nil)
            guard let framePrpoerties = cfFrameProperties as? [String:AnyObject] else {return nil}
            guard let gifProperties = framePrpoerties[kCGImagePropertyGIFDictionary as String] as? [String:AnyObject]
                else { return nil }
            
            // Use kCGImagePropertyGIFUnclampedDelayTime or kCGImagePropertyGIFDelayTime
            if let delayTimeUnclampedProp = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber {
                frameDuration = delayTimeUnclampedProp.floatValue
            } else {
                if let delayTimeProp = gifProperties[kCGImagePropertyGIFDelayTime as String] as? NSNumber {
                    frameDuration = delayTimeProp.floatValue
                }
            }
            
            // Make sure its not too small
            if frameDuration < 0.011 {
                frameDuration = 0.100;
            }
            
            // Add frame to array of frames
            if let frame = CGImageSourceCreateImageAtIndex(src, i, nil) {
                tempTimesArray.append(NSNumber(value: frameDuration))
                framesArray.append(frame)
            }
            
            // Compile total loop time
            time = time + frameDuration
        }
        
        var timesArray = [NSNumber]()
        var base : Float = 0
        for duration in tempTimesArray {
            timesArray.append(NSNumber(value: base))
            base += ( duration.floatValue / time )
        }
        
        timesArray.append(NSNumber(value: 1.0))
        
        let animation = CAKeyframeAnimation(keyPath: "contents")
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.duration = CFTimeInterval(time)
        animation.repeatCount = Float.greatestFiniteMagnitude;
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        animation.values = framesArray
        animation.keyTimes = timesArray
        animation.calculationMode = kCAAnimationDiscrete
        
        return animation;
    }
    
    
    func objNode(fPath: String, contentObj: RLM_Obj) -> SCNNode {
        
        let urlPath = URL(fileURLWithPath: fPath)
        let fileName = urlPath.lastPathComponent
        let fileDir = urlPath.deletingLastPathComponent().path
        print("Attempting to load OBJ model: " + String(fileDir) + " Filename: " + String(fileName))
        
        let objScene = SCNSceneSource(url: urlPath, options: nil)
        
        do {
            let n: SCNNode = try objScene!.scene().rootNode
            return n
        } catch {
            print(error)
        }

        return SCNNode()
 
    }

    
    
    func textNode(contentObj: RLM_Obj, extrusion:Double, color:UIColor) -> SCNNode {
        let text = SCNText(string: contentObj.text, extrusionDepth: 0.1)
        text.alignmentMode = kCAAlignmentCenter
        text.font.withSize(5)
        
        let node = SCNNode(geometry: text)
        node.name = contentObj.name
        node.physicsBody? = .static()
        node.geometry?.materials.first?.diffuse.contents = color
        node.constraints = [SCNBillboardConstraint()]
        
        return node
    }
    
    
    func imageNode(fPath: String, contentObj: RLM_Obj) -> SCNNode {
        let node = SCNNode(geometry: SCNPlane(width: 1, height: 1))
        
        if let img = UIImage(contentsOfFile: fPath) {
            node.physicsBody? = .static()
            node.name = contentObj.name
            node.geometry?.materials.first?.diffuse.contents = UIColor.clear
            node.geometry?.materials.first?.diffuse.contents = img
            node.geometry?.materials.first?.isDoubleSided = true
            node.constraints = [SCNBillboardConstraint()]
        } else {
            // TODO: return Placeholder Obj?
        }
        
        return node
    }
    
    
    func gifNode(fPath: String, contentObj: RLM_Obj) -> SCNNode {
        let gifPlane = SCNPlane(width: 0.5, height: 0.5)
        let animation: CAKeyframeAnimation = createGIFAnimation(
            url: URL(fileURLWithPath: fPath), fDuration: 0.1 )!
        
        let layer = CALayer()
        layer.bounds = CGRect(x: 0, y: 0, width: 500, height: 500)
        layer.add(animation, forKey: "contents")
        layer.anchorPoint = CGPoint(x:0.0, y:1.0)
        
        let gifMaterial = SCNMaterial()
        gifMaterial.isDoubleSided = true
        gifMaterial.diffuse.contents = layer
        
        gifPlane.materials = [gifMaterial]
        
        let node = SCNNode(geometry: gifPlane)
        
        node.constraints = [SCNBillboardConstraint()]
        node.name = contentObj.name

        return node
    }
    
    
    func addDebugObj(objSize: Double)  {
        let node = SCNNode(geometry: SCNSphere(radius: CGFloat(objSize) ))
        node.geometry?.materials.first?.diffuse.contents = UIColor.green
        node.physicsBody? = .static()
        node.name = "TestNode"
        //node.geometry?.materials.first?.diffuse.contents = UIImage(named: "star")
        node.position = SCNVector3(5.0, 0.0, -5.0)
        mainScene.rootNode.addChildNode(node)
        
        let objScene = SCNScene(named: "art.scnassets/bunny.dae")
        objScene!.rootNode.position = SCNVector3(0.0, 0.0, -25.0)
        mainScene.rootNode.addChildNode(objScene!.rootNode)
    }
    
    
    
    
}
