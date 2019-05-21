
import SceneKit
import ARKit
import CoreLocation


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCATextLayerAlignmentMode(_ input: CATextLayerAlignmentMode) -> String {
    return input.rawValue
}

class ContentNode: SCNNode {
    
    let id: String
    let title: String
    let feedId: String
    let info: String

    var feedName:  String = ""
    var feedTopic: String = ""
    var feedUrl:   String = ""
    var contentLink: String = ""
    var directLink:  Bool = false
    
    var anchor: ARAnchor?
    var location: CLLocation!
    
    
    init(id: String, title: String, feedId:String, info:String, location: CLLocation) {
        self.id = id
        self.title = title
        self.info  = info
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
    
    
    func tagComponents(nodeTag: String)  {
        
        for n in self.childNodes {
            n.name = nodeTag
            
            for cn in n.childNodes {
                cn.name = nodeTag
                
                for ccn in cn.childNodes {
                    ccn.name = nodeTag
                    
                    for cccn in ccn.childNodes {
                        cccn.name = nodeTag
                    }
                }
            }
        }
    }
    
    
    func createSphereNode(with radius: CGFloat, color: UIColor) -> SCNNode {
        let geometry = SCNSphere(radius: radius)
        geometry.firstMaterial?.diffuse.contents = color
        let sphereNode = SCNNode(geometry: geometry)
        return sphereNode
    }
    
    
    func addSphere(radius: CGFloat, and color: UIColor) {
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
    
    
    func addText(objectData: RLM_Obj, objText: String, extrusion: CGFloat, fontSize: CGFloat, color: UIColor) {
        var nText = "?"
        
        if objText != "" {
            nText = objText
        }
        
        let text = SCNText(string: nText, extrusionDepth: extrusion)
        text.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        text.firstMaterial?.isDoubleSided = true
        text.chamferRadius = extrusion
        
        if UIFont.fontNames(forFamilyName: objectData.font).count > 0 {
            text.font = UIFont(name: objectData.font, size: 1)
        } 
        
        text.firstMaterial?.diffuse.contents = color

        let ctNode = SCNNode(geometry: text)
        let tx = text.boundingBox.max.x / 2.0
        let ty = text.boundingBox.max.y / 2.0
        let tz = Float(extrusion) / 2.0

        ctNode.pivot = SCNMatrix4MakeTranslation(tx, ty, tz)

        addChildNode(ctNode)
    }
    
    
    func addObj(fPath: String, objectData: RLM_Obj) {
        print("Adding OBJ")

        let urlPath = URL(fileURLWithPath: fPath)
 
        if let objScene = SCNSceneSource(url: urlPath, options: nil) {
            do {
                let node: SCNNode = try objScene.scene().rootNode.clone()
                let objMtl = SCNMaterial()
                objMtl.isDoubleSided = true
                node.geometry?.firstMaterial?.diffuse.contents = UIColor(hexColor: objectData.hex_color)

                objMtl.lightingModel = .constant
                node.geometry?.materials = [objMtl]
                
                addChildNode(node)
            } catch {
                print(error)
            }
        }
    }
    
    
    func addAudio(fPath: String, objectData: RLM_Obj) -> SCNAudioPlayer {
        print("Adding aSource: " + fPath)

        let geometry = SCNPyramid(width: CGFloat(objectData.scale*0.5), height: CGFloat(objectData.scale), length: CGFloat(objectData.scale*0.5))
        geometry.firstMaterial?.diffuse.contents = UIColor(hexColor: objectData.hex_color)
        let icon = SCNNode(geometry: geometry)
        self.removeAllAudioPlayers()
        addChildNode(icon)
        
        let urlPath = URL(fileURLWithPath: fPath)
        let asrc = SCNAudioSource(url: urlPath)
        asrc!.volume = 1
        asrc!.loops  = true
        asrc!.isPositional = true
        asrc!.load()

        self.addAudioPlayer(SCNAudioPlayer(source: asrc!))
        return SCNAudioPlayer(source: asrc!)
    }
    

    func addUSDZ(fPath: String, objectData: RLM_Obj) {
        print("Adding USDZ")
        let urlPath = URL(fileURLWithPath: fPath)
        
        if let objScene = SCNSceneSource(url: urlPath, options: nil) {
            do {
                let node: SCNNode = try objScene.scene().rootNode.clone()
                let s: Float      = Float(0.1 * objectData.scale)
                node.scale        = SCNVector3(x: s, y: s, z: s)
                
                let tx = node.boundingBox.max.x / 2.0
                let ty = node.boundingBox.max.y / 2.0
                let tz = node.boundingBox.max.x / 2.0

                node.pivot = SCNMatrix4MakeTranslation(tx, ty, tz)
                
                addChildNode(node)
            } catch {
                print(error)
            }
        }
    }
    
    
    func addDemoContent(fPath: String, objectData: RLM_Obj) {
        let node = SCNNode(geometry: SCNPlane(width: 1, height: 1))
        
        if let img = UIImage(named: fPath) {
            node.physicsBody? = .static()
            node.name = objectData.name
            node.geometry?.materials.first?.diffuse.contents = UIColor.clear
            node.geometry?.materials.first?.diffuse.contents = img
            node.geometry?.materials.first?.isDoubleSided = true
            
            addChildNode(node)
        }
        
        addChildNode(node)
    }

    
    func addImage(fPath: String, objectData: RLM_Obj) {
        self.geometry?.materials.first?.diffuse.contents = UIColor.clear

        let node = SCNNode(geometry: SCNPlane(width: 1, height: 1))
        node.geometry?.materials.first?.diffuse.contents = UIColor.clear

        if let img = UIImage(contentsOfFile: fPath) {
            node.physicsBody? = .static()
            node.name = objectData.name
            node.geometry?.materials.first?.diffuse.contents = img
            node.geometry?.materials.first?.isDoubleSided = true
        }
        
        addChildNode(node)
    }
    
    
    func addGif(fPath: String, objectData: RLM_Obj) {
        let gifPlane = SCNPlane(width: CGFloat(objectData.scale), height: CGFloat(objectData.scale))
       
        let layer = CALayer()
        layer.bounds = CGRect(x: 0, y: 0, width: 500, height: 500)
        
        let animation: CAKeyframeAnimation = createGIFAnimation(
            url: URL(fileURLWithPath: fPath), fDuration: 0.05 )!
        
        layer.add(animation, forKey: "contents")
        layer.anchorPoint = CGPoint(x:0.0, y:1.0)
        
        let gifMaterial = SCNMaterial()
        gifMaterial.isDoubleSided = true
        gifMaterial.diffuse.contents = layer
        gifMaterial.lightingModel = .constant
        
        gifPlane.materials = [gifMaterial]
        
        let node = SCNNode(geometry: gifPlane)
        node.name = objectData.name
        
        addChildNode(node)
    }
    
}


