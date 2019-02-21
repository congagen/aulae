
import SceneKit
import ARKit
import CoreLocation


class ContentNode: SCNNode {
    
    let title: String
    var anchor: ARAnchor?
    var location: CLLocation!
    
    
    init(title: String, location: CLLocation) {
        self.title = title
        super.init()
        let billboardConstraint = SCNBillboardConstraint()
        // billboardConstraint.freeAxes = SCNBillboardAxis.Y
        constraints = [billboardConstraint]
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
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
    
    
    func createSphereNode(with radius: CGFloat, color: UIColor) -> SCNNode {
        let geometry = SCNSphere(radius: radius)
        geometry.firstMaterial?.diffuse.contents = color
        let sphereNode = SCNNode(geometry: geometry)
        return sphereNode
    }
    
    
    func addSphere(with radius: CGFloat, and color: UIColor) {
        let sphereNode = createSphereNode(with: radius, color: color)
        addChildNode(sphereNode)
    }
    
    
    func addDebugNode(with radius: CGFloat, and color: UIColor, and text: String) {
        let sphereNode = createSphereNode(with: radius, color: color)
        let newText = SCNText(string: title, extrusionDepth: 0.05)
        newText.font = UIFont (name: "AvenirNext-Medium", size: 1)
        newText.firstMaterial?.diffuse.contents = UIColor.red
        let _textNode = SCNNode(geometry: newText)
        let annotationNode = SCNNode()
        annotationNode.addChildNode(_textNode)
        annotationNode.position = sphereNode.position
        addChildNode(sphereNode)
        addChildNode(annotationNode)
    }
    
    
    func addText(nodeText: String, extrusion:Double, color:UIColor) {
        let text = SCNText(string: nodeText, extrusionDepth: 0.1)
        text.alignmentMode = kCAAlignmentCenter
        text.font.withSize(5)
        
        let node = SCNNode(geometry: text)
        node.physicsBody? = .static()
        node.geometry?.materials.first?.diffuse.contents = color
        node.constraints = [SCNBillboardConstraint()]
        
        addChildNode(node)
    }
    
    
    func addObj(fPath: String, contentObj: RLM_Obj) {

        let urlPath = URL(fileURLWithPath: fPath)
 
        if let objScene = SCNSceneSource(url: urlPath, options: nil) {
            do {
                let node: SCNNode = try objScene.scene().rootNode
                addChildNode(node)
            } catch {
                print(error)
            }
        }
        
    }
    
    
    func addImage(fPath: String, contentObj: RLM_Obj) {
        let node = SCNNode(geometry: SCNPlane(width: 1, height: 1))
        
        if let img = UIImage(contentsOfFile: fPath) {
            node.physicsBody? = .static()
            node.name = contentObj.name
            node.geometry?.materials.first?.diffuse.contents = UIColor.clear
            node.geometry?.materials.first?.diffuse.contents = img
            node.geometry?.materials.first?.isDoubleSided = true
            node.constraints = [SCNBillboardConstraint()]
            addChildNode(node)
        } else {
            // TODO: Log Error?
        }
        
    }
    
    
    func addGif(fPath: String, contentObj: RLM_Obj) {
        let gifPlane = SCNPlane(width: 0.5, height: 0.5)
       
        let layer = CALayer()
        layer.bounds = CGRect(x: 0, y: 0, width: 500, height: 500)
        
        let animation: CAKeyframeAnimation = createGIFAnimation(
            url: URL(fileURLWithPath: fPath), fDuration: 0.1 )!
        
        layer.add(animation, forKey: "contents")
        layer.anchorPoint = CGPoint(x:0.0, y:1.0)
        
        let gifMaterial = SCNMaterial()
        gifMaterial.isDoubleSided = true
        gifMaterial.diffuse.contents = layer
        
        gifPlane.materials = [gifMaterial]
        
        let node = SCNNode(geometry: gifPlane)
        
        node.constraints = [SCNBillboardConstraint()]
        node.name = contentObj.name
        
        addChildNode(node)
    }
    
}
