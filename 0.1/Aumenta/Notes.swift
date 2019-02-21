

//func addContentToScene(contentObj: RLM_Obj, fPath: String) {
//    print("addContentToScene: " + String(contentObj.id))
//    
//    let rawObjectGps     = CGPoint(x: contentObj.lat, y: contentObj.lng)
//    
//    let rawDeviceGpsCCL  = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)! )
//    let rawObjectGpsCCL  = CLLocation(latitude: contentObj.lat, longitude: contentObj.lng)
//    
//    let translation      = MatrixHelper.transformMatrix(for: matrix_identity_float4x4, originLocation: rawDeviceGpsCCL, location: rawObjectGpsCCL)
//    let translationSCNV  = SCNVector3.positionFromTransform(translation)
//    
//    let objectDistance   = rawDeviceGpsCCL.distance(from: rawObjectGpsCCL)
//    
//    let deviceXYZPos     = valConv.gps_to_ecef( latitude: Double(rawDeviceGpsCCL.coordinate.latitude), longitude: Double(rawDeviceGpsCCL.coordinate.longitude), altitude: 0.01 )
//    let objectXYZPos     = valConv.gps_to_ecef( latitude: Double(rawObjectGpsCCL.coordinate.latitude), longitude: Double(rawObjectGpsCCL.coordinate.longitude), altitude: 0.01 )
//    let compositeXY      = CGPoint(x: (objectXYZPos[0] - deviceXYZPos[0]) / 1000000.0, y: (objectXYZPos[1] - deviceXYZPos[1]) / 1000000.0 )
//    
//    let compositeXYTra   = CGPoint(x: Double(translationSCNV.x) / 1000000.0, y: Double(translationSCNV.z) / 1000000.0 )
//    
//    let vPos = 0.0
//    let basePos          = SCNVector3(compositeXY.x,    CGFloat(vPos), compositeXY.y)
//    let basePosTra       = SCNVector3(compositeXYTra.x, CGFloat(vPos), compositeXYTra.y)
//    
//    print("Distance:     " + String(objectDistance))
//    print("RawObjectGps: " + String(rawObjectGps.x.description) + ", " + String(rawObjectGps.y.description))
//    
//    print("BasePos:      " + String(basePos.x) + ", " + String(basePos.y) + ", " + String(basePos.z))
//    print("TrnsPos:      " + String(basePosTra.x) + ", " + String(basePosTra.y) + ", " + String(basePosTra.z))


//    double rad = angle*M_PI/180;
//
//    newX = x * cos(rad) - y * sin(rad);
//    newY = y * cos(rad) + x * sin(rad);


//    func rotateLatLong(lat:Double, long:Double, angle: Double) -> CGPoint {
//        let rad: Double = angle * (Double.pi / 180.0)
//
//        let newX = lat  * cos(rad) - long * sin(rad)
//        let newY = long * cos(rad) + lat * sin(rad)
//
//        return CGPoint(x: newX, y: newY)
//    }



////
////  ARViewer_.swift
////  Aumenta
////
////  Created by Tim Sandgren on 2019-02-11.
////  Copyright © 2019 Abstraqata. All rights reserved.
//
//
//import UIKit
//import SceneKit
//import Foundation
//import MapKit
//import ARKit
//
//import Realm
//import RealmSwift
//
//class ARViewer: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
//    
//    let realm = try! Realm()
//    lazy var session: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
//    lazy var feeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
//    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
//    
//    let valConv = ValConverters()
//    
//    var deviceHeading: Float = 0
//    var deviceHeadingNormal: Float = 0
//    var currentCamTransform: simd_float4x4 = simd_float4x4(float4(0), float4(0), float4(0), float4(0))
//    var currentCamEuler: vector_float3 = vector_float3(x:0, y:0, z:0)
//    
//    var camFrame: ARFrame? = nil
//    var cam: ARCamera? = nil
//    
//    var updateTimer = Timer()
//    var updateInterval: Double = 10
//    
//    var mainScene = SCNScene()
//    
//    
//    @IBAction func refreshBtnAction(_ sender: UIBarButtonItem) {
//        updateScene()
//    }
//    
//    @IBOutlet var sceneView: ARSCNView!
//    
//    
//    @IBAction func sharePhotoBtn(_ sender: UIBarButtonItem) {
//        // let capImg = UIImage(cgImage: sceneView.snapshot().cgImage!)
//        
//        let snapShot = sceneView.snapshot()
//        //let jpg = UIImageJPEGRepresentation(snapShot, 1.0)
//        
//        let imageToShare = [snapShot]
//        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
//        activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook ]
//        
//        activityViewController.popoverPresentationController?.sourceView = self.view
//        self.present(activityViewController, animated: true, completion: nil)
//    }
//    
//    
//    func objectsInRange(position: CLLocation, useManualRange: Bool, manualRange: Double) -> [RLM_Obj] {
//        var objList: [RLM_Obj] = []
//        
//        if (useManualRange) {
//            objList = feedObjects.filter({ (CLLocation(latitude: $0.lat, longitude: $0.lng).distance(from: position) <= Double(manualRange)) })
//        } else {
//            objList = feedObjects.filter({ (CLLocation(latitude: $0.lat, longitude: $0.lng).distance(from: position) <= Double($0.radius))   })
//        }
//        
//        return objList
//    }
//    
//    
//    func rotatePoint(target: CGPoint, aroundOrigin origin: CGPoint, byDegrees: CGFloat) -> CGPoint {
//        let dx = target.x - origin.x
//        let dy = target.y - origin.y
//        let radius = sqrt(dx * dx + dy * dy)
//        let azimuth = atan2(dy, dx) // in radians
//        let newAzimuth = azimuth + byDegrees * CGFloat(M_PI / 180.0) // convert it to radians
//        let x = origin.x + radius * cos(newAzimuth)
//        let y = origin.y + radius * sin(newAzimuth)
//        return CGPoint(x: x, y: y)
//    }
//    
//    
//    func addContentToScene(contentObj: RLM_Obj, fPath: String) {
//        print("addContentToScene: " + String(contentObj.id))
//        print(currentCamEuler)
//        
//        let devicePos = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!)
//        
//        let objectXYZPos = valConv.gps_to_ecef( latitude: contentObj.lat, longitude: contentObj.lng, altitude: 0.01 )
//        let deviceXYZPos = valConv.gps_to_ecef( latitude: devicePos.coordinate.latitude, longitude: devicePos.coordinate.longitude, altitude: 0.01 )
//        
//        
//        let xPos = (((objectXYZPos[0] - objectXYZPos[0]) ) / 1000000.0)
//        let yPos = (((objectXYZPos[1] - objectXYZPos[1]) ) / 1000000.0)
//        let vPos = 0.0
//        
//        let comPos = rotatePoint(target: CGPoint(x: xPos, y: yPos), aroundOrigin: CGPoint(x: 0, y: 0), byDegrees: CGFloat(deviceHeadingNormal*360))
//        
//        if fPath != "" {
//            
//            if contentObj.type.lowercased() == "obj" {
//                print("ADDING OBJ TO SCENE: " + fPath)
//                
//                let node = objNode(fPath: fPath, contentObj: contentObj)
//                node.position = SCNVector3(xPos, vPos, yPos)
//                mainScene.rootNode.addChildNode(node)
//            }
//            
//            if contentObj.type.lowercased() == "image" {
//                print("ADDING IMAGE TO SCENE")
//                
//                let node = imageNode(fPath: fPath, contentObj: contentObj)
//                node.position = SCNVector3(xPos, vPos, yPos)
//                //                node.look(at: sceneCenter!)
//                
//                mainScene.rootNode.addChildNode(node)
//            }
//            
//            if contentObj.type.lowercased() == "gif" {
//                print("ADDING GIF TO SCENE")
//                
//                let node = gifNode(fPath: fPath, contentObj: contentObj)
//                node.position = SCNVector3(comPos.x, CGFloat(vPos), comPos.y)
//                mainScene.rootNode.addChildNode(node)
//            }
//        } else {
//            // TODO: Add placeholder if allowed in settings
//        }
//    }
//    
//    
//    func updateScene() {
//        print("Update Scene")
//        
//        let curPos = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!)
//        
//        // TODO:  Get search range
//        let objsInRange   = objectsInRange(position: curPos, useManualRange: true, manualRange: 100000000000)
//        let activeInRange = objsInRange.filter({$0.active && !$0.deleted})
//        
//        sceneView.pointOfView?.rotate(by: SCNQuaternion(x: 0, y: 0, z: 0, w: 0), aroundTarget: (sceneView.pointOfView?.position)!)
//        
//        mainScene.rootNode.enumerateChildNodes { (node, stop) in
//            node.removeFromParentNode()
//        }
//        
//        for o in activeInRange {
//            print("Obj in range: ")
//            
//            if o.filePath != "" && !(o.type == "text") {
//                let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
//                let fileName = (URL(string: o.filePath)?.lastPathComponent)!
//                let destinationUrl = documentsUrl.appendingPathComponent(fileName)
//                
//                print("UpdateScene: activeInRange: " + String(o.id))
//                
//                if (FileManager.default.fileExists(atPath: (destinationUrl?.path)! )) {
//                    print("FileManager.default.fileExists")
//                    
//                    addContentToScene(contentObj: o, fPath: (destinationUrl?.path)! )
//                    
//                } else {
//                    print("ERROR: FEED CONTENT: MISSING DATA: " + String(o.filePath))
//                }
//            } else {
//                if (o.type == "text") {
//                    addContentToScene(contentObj: o, fPath:"" )
//                }
//            }
//        }
//        
//    }
//    
//    
//    @objc func mainUpdate() {
//        print("mainUpdate: ARViewer")
//        
//        if session.count > 0 {
//            if updateTimer.timeInterval != updateInterval {
//                updateTimer.invalidate()
//            }
//            
//            updateInterval = session.first!.feedUpdateInterval
//            
//            if !updateTimer.isValid {
//                updateTimer = Timer.scheduledTimer(
//                    timeInterval: updateInterval,
//                    target: self, selector: #selector(mainUpdate),
//                    userInfo: nil, repeats: true)
//            }
//        }
//    }
//    
//    
//    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        camFrame = frame
//        cam = camFrame!.camera
//        
//        currentCamTransform = cam!.transform
//        currentCamEuler = cam!.eulerAngles
//        deviceHeading = currentCamEuler.y
//        deviceHeadingNormal = ((currentCamEuler.y + 0.00001) + .pi) / (2 * .pi)
//        
//        //let camHeading = valConv.cameraHeading(camera: cam)
//        
//        print("DeviceHeadingNormal: " + String(deviceHeadingNormal))
//        
//    }
//    
//    
//    func initScene() {
//        print("initScene")
//        
//        mainScene = SCNScene(named: "art.scnassets/main.scn")!
//        sceneView.scene = mainScene
//        
//        sceneView.session.delegate = self
//        sceneView.delegate = self
//        sceneView.showsStatistics = false
//    }
//    
//    
//    override func viewDidLoad() {
//        print("viewDidLoad")
//    }
//    
//    
//    override func viewDidAppear(_ animated: Bool) {
//        print("viewDidAppear")
//        print(currentCamEuler)
//        initScene()
//        updateScene()
//    }
//    
//    override func viewWillAppear(_ animated: Bool) {
//        print("viewWillAppear")
//        
//        let configuration = AROrientationTrackingConfiguration()
//        sceneView.session.run(configuration)
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        sceneView.session.pause()
//    }
//    
//    func session(_ session: ARSession, didFailWithError error: Error) {
//        print(error)
//        print("ArKit ViewerVC: didFailWithError")
//    }
//    
//    func sessionWasInterrupted(_ session: ARSession) {
//        print("ArKit ViewerVC: sessionWasInterrupted")
//    }
//    
//    func sessionInterruptionEnded(_ session: ARSession) {
//        print("ArKit ViewerVC: sessionInterruptionEnded")
//    }
//    
//}
//
















//  SceneNodeUtils.swift
//  Aumenta
//
//  Created by Tim Sandgren on 2019-02-18.
//  Copyright © 2019 Abstraqata. All rights reserved.
//
//
//import UIKit
//import SceneKit
//import Foundation
//import ARKit
//
//
//extension ARViewer {
//
//
//    func createGIFAnimation(url:URL, fDuration:Float) -> CAKeyframeAnimation? {
//
//        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
//        let frameCount = CGImageSourceGetCount(src)
//
//        var time : Float = 0
//
//        var framesArray = [AnyObject]()
//        var tempTimesArray = [NSNumber]()
//
//        for i in 0..<frameCount {
//
//            var frameDuration : Float = fDuration;
//
//            let cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(src, i, nil)
//            guard let framePrpoerties = cfFrameProperties as? [String:AnyObject] else {return nil}
//            guard let gifProperties = framePrpoerties[kCGImagePropertyGIFDictionary as String] as? [String:AnyObject]
//                else { return nil }
//
//            // Use kCGImagePropertyGIFUnclampedDelayTime or kCGImagePropertyGIFDelayTime
//            if let delayTimeUnclampedProp = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber {
//                frameDuration = delayTimeUnclampedProp.floatValue
//            } else {
//                if let delayTimeProp = gifProperties[kCGImagePropertyGIFDelayTime as String] as? NSNumber {
//                    frameDuration = delayTimeProp.floatValue
//                }
//            }
//
//            // Make sure its not too small
//            if frameDuration < 0.011 {
//                frameDuration = 0.100;
//            }
//
//            // Add frame to array of frames
//            if let frame = CGImageSourceCreateImageAtIndex(src, i, nil) {
//                tempTimesArray.append(NSNumber(value: frameDuration))
//                framesArray.append(frame)
//            }
//
//            // Compile total loop time
//            time = time + frameDuration
//        }
//
//        var timesArray = [NSNumber]()
//        var base : Float = 0
//        for duration in tempTimesArray {
//            timesArray.append(NSNumber(value: base))
//            base += ( duration.floatValue / time )
//        }
//
//        timesArray.append(NSNumber(value: 1.0))
//
//        let animation = CAKeyframeAnimation(keyPath: "contents")
//        animation.beginTime = AVCoreAnimationBeginTimeAtZero
//        animation.duration = CFTimeInterval(time)
//        animation.repeatCount = Float.greatestFiniteMagnitude;
//        animation.isRemovedOnCompletion = false
//        animation.fillMode = kCAFillModeForwards
//        animation.values = framesArray
//        animation.keyTimes = timesArray
//        animation.calculationMode = kCAAnimationDiscrete
//
//        return animation;
//    }
//
//
//    func objNode(fPath: String, contentObj: RLM_Obj) -> SCNNode {
//
//        let urlPath = URL(fileURLWithPath: fPath)
//        let fileName = urlPath.lastPathComponent
//        let fileDir = urlPath.deletingLastPathComponent().path
//        print("Attempting to load OBJ model: " + String(fileDir) + " Filename: " + String(fileName))
//
//        let objScene = SCNSceneSource(url: urlPath, options: nil)
//
//        do {
//            let n: SCNNode = try objScene!.scene().rootNode
//            return n
//        } catch {
//            print(error)
//        }
//
//        return SCNNode()
//
//    }
//
//
//
//    func textNode(contentObj: RLM_Obj, extrusion:Double, color:UIColor) -> SCNNode {
//        let text = SCNText(string: contentObj.text, extrusionDepth: 0.1)
//        text.alignmentMode = kCAAlignmentCenter
//        text.font.withSize(5)
//
//        let node = SCNNode(geometry: text)
//        node.name = contentObj.name
//        node.physicsBody? = .static()
//        node.geometry?.materials.first?.diffuse.contents = color
//        node.constraints = [SCNBillboardConstraint()]
//
//        return node
//    }
//
//
//    func imageNode(fPath: String, contentObj: RLM_Obj) -> SCNNode {
//        let node = SCNNode(geometry: SCNPlane(width: 1, height: 1))
//
//        if let img = UIImage(contentsOfFile: fPath) {
//            node.physicsBody? = .static()
//            node.name = contentObj.name
//            node.geometry?.materials.first?.diffuse.contents = UIColor.clear
//            node.geometry?.materials.first?.diffuse.contents = img
//            node.geometry?.materials.first?.isDoubleSided = true
//            node.constraints = [SCNBillboardConstraint()]
//        } else {
//            // TODO: return Placeholder Obj?
//        }
//
//        return node
//    }
//
//
//    func gifNode(fPath: String, contentObj: RLM_Obj) -> SCNNode {
//        let gifPlane = SCNPlane(width: 0.5, height: 0.5)
//        let animation: CAKeyframeAnimation = createGIFAnimation(
//            url: URL(fileURLWithPath: fPath), fDuration: 0.1 )!
//
//        let layer = CALayer()
//        layer.bounds = CGRect(x: 0, y: 0, width: 500, height: 500)
//        layer.add(animation, forKey: "contents")
//        layer.anchorPoint = CGPoint(x:0.0, y:1.0)
//
//        let gifMaterial = SCNMaterial()
//        gifMaterial.isDoubleSided = true
//        gifMaterial.diffuse.contents = layer
//
//        gifPlane.materials = [gifMaterial]
//
//        let node = SCNNode(geometry: gifPlane)
//
//        node.constraints = [SCNBillboardConstraint()]
//        node.name = contentObj.name
//
//        return node
//    }
//
//
//    func addDebugObj(objSize: Double)  {
//        let node = SCNNode(geometry: SCNSphere(radius: CGFloat(objSize) ))
//        node.geometry?.materials.first?.diffuse.contents = UIColor.green
//        node.physicsBody? = .static()
//        node.name = "TestNode"
//        //node.geometry?.materials.first?.diffuse.contents = UIImage(named: "star")
//        node.position = SCNVector3(5.0, 0.0, -5.0)
//        mainScene.rootNode.addChildNode(node)
//
//        let objScene = SCNScene(named: "art.scnassets/bunny.dae")
//        objScene!.rootNode.position = SCNVector3(0.0, 0.0, -25.0)
//        mainScene.rootNode.addChildNode(objScene!.rootNode)
//    }
//
//
//
//
//}
