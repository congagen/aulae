//
//  ARViewer_.swift
//  Aumenta
//
//  Created by Tim Sandgren on 2019-02-11.
//  Copyright © 2019 Abstraqata. All rights reserved.


import UIKit
import SceneKit
import Foundation
import MapKit
import ARKit

import Realm
import RealmSwift


class ARViewer: UIViewController, ARSCNViewDelegate {
    
    
    let realm = try! Realm()
    lazy var session: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var feeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
    
    var currentCamTransform: simd_float4x4 = simd_float4x4(float4(0), float4(0), float4(0), float4(0))
    let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(rec:)))

    var camFrame: ARFrame? = nil
    var cam: ARCamera? = nil
    
    var updateTimer = Timer()
    var updateInterval: Double = 10

    var mainScene = SCNScene()
    
    @IBAction func refreshBtnAction(_ sender: UIBarButtonItem) {
        updateScene()
    }
    
    @IBOutlet var sceneView: ARSCNView!
    
    @IBAction func sharePhotoBtn(_ sender: UIBarButtonItem) {
        // let capImg = UIImage(cgImage: sceneView.snapshot().cgImage!)
        
        let snapShot = try sceneView.snapshot()
        //let jpg = UIImageJPEGRepresentation(snapShot, 1.0)
        
        let imageToShare = [snapShot]
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook ]
        
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
        
    }
    
    
    func sharePhoto(){
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
    
    
    
    @objc func handleTap(rec: UITapGestureRecognizer){
        
        if rec.state == .ended {
            let location: CGPoint = rec.location(in: sceneView)
            let hits = self.sceneView.hitTest(location, options: nil)
            if !hits.isEmpty{
                let tappedNode = hits.first?.node
                print(tappedNode?.name!)
            }
        }
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
    

    func loadCollada(path: String) -> SCNNode {

        let urlPath = URL(fileURLWithPath: path)
        let fileName = urlPath.lastPathComponent
        let fileDir = urlPath.deletingLastPathComponent().path

        print("Attempting to load model: " + String(fileDir) + " Filename: " + String(fileName))

        do {
            let scene = try SCNScene(url: urlPath, options: nil)
            return scene.rootNode
        } catch {
            print(error)
        }

        return SCNNode()
    }


    func obejctsInRange(position: CLLocation, useManualRange: Bool, manualRange: Double) -> [RLM_Obj] {
        var objList: [RLM_Obj] = []

        if (useManualRange) {
            objList = feedObjects.filter({ (CLLocation(latitude: $0.lat, longitude: $0.lng).distance(from: position) <= Double(manualRange)) })
        } else {
            objList = feedObjects.filter({ (CLLocation(latitude: $0.lat, longitude: $0.lng).distance(from: position) <= Double($0.radius))   })
        }

        return objList
    }
    
    
    func textNode(contentObj: RLM_Obj, extrusion:Double) -> SCNNode {
        let text = SCNText(string: contentObj.text, extrusionDepth: 0.1)
        text.alignmentMode = kCAAlignmentCenter
        text.chamferRadius = 5
//        text.isWrapped = true
        text.font.withSize(5)
        
        let node = SCNNode(geometry: text)
        
        node.physicsBody? = .static()
        node.name = contentObj.name
        node.geometry?.materials.first?.diffuse.contents = UIColor.black
        node.position = SCNVector3(0.0, 0.0, -200)
        node.constraints = [SCNBillboardConstraint()]
        
        return node
    }
    
    
    func addContentToScene(contentObj: RLM_Obj, fPath: String) {
        // Latitudes range from 0 to 90. Longitudes range from 0 to 180.
        // [+] if obj.lat/long < user.lat/long else [-] ?
        print("Inserting Object: " + String(contentObj.id))

         let devicePos = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!)
        
        //SceneXYZ <- let objPos = CLLocation(latitude: contentObj.lat, longitude: contentObj.lng)

        let valConv = ValConverters()
        let arPos = valConv.gps_to_ecef(latitude: contentObj.lat, longitude: contentObj.lng, altitude: 1.0)

//        let distance = devicePos.distance(
//            from: CLLocation( latitude: contentObj.lat, longitude: contentObj.lng )
//        )
        
        let xPos = arPos[0] / 1000000.0
        let yPos = 0.0
        let zPos = arPos[1] / 1000000.0
        
        print(arPos)
        
        if fPath != "" {
            if contentObj.type.lowercased() == "image" {
                print("ADDING IMAGE TO SCENE")
                
                if let img = UIImage(contentsOfFile: fPath) {
                    let node = SCNNode(geometry: SCNPlane(width: 1, height: 1))
                    
                    node.physicsBody? = .static()
                    node.name = contentObj.name
                    node.geometry?.materials.first?.diffuse.contents = UIColor.white
                    node.geometry?.materials.first?.diffuse.contents = img
                    node.geometry?.materials.first?.isDoubleSided = true
                    node.position = SCNVector3(xPos, yPos, zPos)
                    node.constraints = [SCNBillboardConstraint()]
                    
                    mainScene.rootNode.addChildNode(node)
                }
    
            }
            
            if contentObj.type.lowercased() == "dae" {
                print("ADDING DAEOBJ TO SCENE: " + fPath)
            
                let objNode =  loadCollada(path: fPath)
                mainScene.rootNode.addChildNode(objNode)
            }
            
            if contentObj.type.lowercased() == "gif" {
                print("ADDING GIF TO SCENE")
                
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
                node.position = SCNVector3(xPos, yPos, zPos)
                node.constraints = [SCNBillboardConstraint()]

                mainScene.rootNode.addChildNode(node)
            }
        }
    }
    
    
    func updateScene() {
        print("Update Scene")
        
        // Scenes in range
        let curPos = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!)
        
        // TODO:  Get search range
        let objsInRange = obejctsInRange(position: curPos, useManualRange: true, manualRange: 100000000000)
        
        mainScene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
        
        for o in objsInRange {
            print("Obj in range: ")
            
            if o.filePath != "" && !(o.type == "text") {
                let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
                let fileName = (URL(string: o.filePath)?.lastPathComponent)!
                let destinationUrl = documentsUrl.appendingPathComponent(fileName)
                
                print("UpdateScene: objsInRange: " + String(o.id))
                
                if (FileManager.default.fileExists(atPath: (destinationUrl?.path)! )) {
                    print("FileManager.default.fileExists")
                    
                    print("objsInScene.filter({$0.name == String(o.id)}).count == 0")
                    addContentToScene(contentObj: o, fPath: (destinationUrl?.path)! )

                } else {
                    print("ERROR: FEED CONTENT: MISSING DATA: " + String(o.filePath))
                }
            } else {
                if (o.type == "text") {
                    addContentToScene(contentObj: o, fPath:"" )
                }
            }
        }
    }
    
    
    @objc func mainUpdate() {
        print("mainUpdate: ARViewer")
        
        // updateScene()
        
        if session.count > 0 {
            if updateTimer.timeInterval != updateInterval {
                updateTimer.invalidate()
            }
            
            updateInterval = session.first!.feedUpdateInterval
            
            if !updateTimer.isValid {
                updateTimer = Timer.scheduledTimer(
                    timeInterval: updateInterval,
                    target: self, selector: #selector(mainUpdate),
                    userInfo: nil, repeats: true)
            }
        }
    }
    
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Do something with the new transform

        if (!(camFrame != nil)) {
            camFrame = frame
        }

        if (!(cam != nil)) {
            cam = frame.camera
        }

        currentCamTransform = frame.camera.transform
    }
    
    
    func initScene() {
        sceneView.delegate = self
        sceneView.showsStatistics = false
        
        mainScene = SCNScene(named: "art.scnassets/main.scn")!
        sceneView.scene = mainScene
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
    }
    
    
    override func viewDidLoad() {
        initScene()
        updateScene()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear")
//        super.viewWillAppear(animated)
        
        let configuration = AROrientationTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print(error)
        print("ArKit ViewerVC: didFailWithError")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("ArKit ViewerVC: sessionWasInterrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("ArKit ViewerVC: sessionInterruptionEnded")
    }
    
}

