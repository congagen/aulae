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
    
    
    func loadCollada(path: String) -> SCNNode {
        
        let urlPath = URL(fileURLWithPath: path)
        let fileName = urlPath.lastPathComponent
        let fileDir = urlPath.deletingLastPathComponent().path
        
        print("Attempting to load DAE model: " + String(fileDir) + " Filename: " + String(fileName))
        
        do {
            let scene = try SCNScene(url: urlPath, options: nil)
            return scene.rootNode
        } catch {
            print(error)
        }
        
        return SCNNode()
    }
    
    
    func daeNode(fPath: String, contentObj: RLM_Obj) -> SCNNode {
        let node =  loadCollada(path: fPath)
        node.name = contentObj.name
        node.physicsBody? = .static()

        return node
    }
    
    
    func textNode(contentObj: RLM_Obj, extrusion:Double) -> SCNNode {
        let text = SCNText(string: contentObj.text, extrusionDepth: 0.1)
        text.alignmentMode = kCAAlignmentCenter
        text.font.withSize(5)
        
        let node = SCNNode(geometry: text)
        node.name = contentObj.name

        node.physicsBody? = .static()
        node.geometry?.materials.first?.diffuse.contents = UIColor.black
        node.constraints = [SCNBillboardConstraint()]
        
        return node
    }
    
    
    func imageNode(fPath: String, contentObj: RLM_Obj) -> SCNNode {
        let node = SCNNode(geometry: SCNPlane(width: 1, height: 1))
        
        if let img = UIImage(contentsOfFile: fPath) {
            node.physicsBody? = .static()
            node.name = contentObj.name
            node.geometry?.materials.first?.diffuse.contents = UIColor.white
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
        layer.anchorPoint = CGPoint(x:0.0,y:1.0)
        
        let gifMaterial = SCNMaterial()
        gifMaterial.isDoubleSided = true
        gifMaterial.diffuse.contents = layer
        
        gifPlane.materials = [gifMaterial]
        
        let node = SCNNode(geometry: gifPlane)
        node.constraints = [SCNBillboardConstraint()]
        node.name = contentObj.name

        return node
    }
    
    


    
    
}
