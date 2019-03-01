
import SceneKit
import ARKit
import CoreLocation


class ContentNode: SCNNode {
    
    let id: String
    let title: String
    let feedId: String
    var anchor: ARAnchor?
    var location: CLLocation!
    
    
    init(id: String, title: String, feedId:String, location: CLLocation) {
        self.id = id
        self.title = title
        self.feedId = feedId
        self.location = location

        super.init()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func createGIFAnimation(url:URL, fDuration:Float) -> CAKeyframeAnimation? {
        print("createGIFAnimation")
        
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
            
            if let delayTimeUnclampedProp = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber {
                frameDuration = delayTimeUnclampedProp.floatValue
            } else {
                if let delayTimeProp = gifProperties[kCGImagePropertyGIFDelayTime as String] as? NSNumber {
                    frameDuration = delayTimeProp.floatValue
                }
            }
            
            if frameDuration < 0.011 {
                frameDuration = 0.100;
            }
            
            if let frame = CGImageSourceCreateImageAtIndex(src, i, nil) {
                tempTimesArray.append(NSNumber(value: frameDuration))
                framesArray.append(frame)
            }
            
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
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.values = framesArray
        animation.keyTimes = timesArray
        animation.calculationMode = CAAnimationCalculationMode.discrete
        
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
    
    
    func addText(contentObj: RLM_Obj, extrusion: CGFloat, fontSize: CGFloat, color: UIColor) {
        
        var nText = "?"
        
        if contentObj.text != "" {
            nText = contentObj.text
        }
        
        let text = SCNText(string: nText, extrusionDepth: extrusion)
        text.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        text.firstMaterial?.isDoubleSided = true
        text.chamferRadius = extrusion
        text.font = UIFont (name: "AvenirNext-Medium", size: fontSize)
        text.firstMaterial?.diffuse.contents = color

        let ctNode = SCNNode(geometry: text)
        let max = text.boundingBox.max
        let min = text.boundingBox.min
        
        let tx = (max.x - min.x) / 2.0
        let ty = min.y
        let tz = Float(extrusion) / 2.0
        
        ctNode.pivot = SCNMatrix4MakeTranslation(tx, ty, tz)
        
        addChildNode(ctNode)
    }
    
    
    func addObj(fPath: String, contentObj: RLM_Obj) {

        let urlPath = URL(fileURLWithPath: fPath)
 
        if let objScene = SCNSceneSource(url: urlPath, options: nil) {
            do {
                let node: SCNNode = try objScene.scene().rootNode.clone()

                addChildNode(node)
            } catch {
                print(error)
            }
        }
    }
    
    
    func addAudio(fPath: String, contentObj: RLM_Obj) {
        let geometry = SCNSphere(radius: CGFloat(contentObj.scale))
        geometry.firstMaterial?.diffuse.contents = UIColor(hexColor: contentObj.hex_color)
        let node = SCNNode(geometry: geometry)
        
        let urlPath = URL(fileURLWithPath: fPath)
        
        if let aSource: SCNAudioSource = SCNAudioSource(url: urlPath) {
            print("aSource OK")
            aSource.volume = 1
            aSource.loops  = true
            aSource.isPositional = false
            aSource.shouldStream = false
            aSource.load()
            let player = SCNAudioPlayer(source: aSource)
            node.addAudioPlayer(player)
            
            addChildNode(node)
        } else {
            print(urlPath)
        }
        
    }
    

    func addUSDZ(fPath: String, contentObj: RLM_Obj, position: SCNVector3) {
        
        let urlPath = URL(fileURLWithPath: fPath)
        
        if let objScene = SCNSceneSource(url: urlPath, options: nil) {
            do {
                let node: SCNNode = try objScene.scene().rootNode.clone()
                let s:Float = Float(0.1 * contentObj.scale)
                node.scale = SCNVector3(x: s, y: s, z: s)
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
            
            addChildNode(node)
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
        
        node.name = contentObj.name
        
        addChildNode(node)
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCATextLayerAlignmentMode(_ input: CATextLayerAlignmentMode) -> String {
	return input.rawValue
}
