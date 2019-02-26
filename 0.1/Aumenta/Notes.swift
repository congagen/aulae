//
//  ARViewer_.swift
//  Aumenta
//
//  Created by Tim Sandgren on 2019-02-11.
//  Copyright Â© 2019 Abstraqata. All rights reserved.

//import Foundation
//import CoreLocation
//import ARKit
//import Realm
//import RealmSwift
//
//
//class ARViewer: UIViewController, ARSCNViewDelegate, ARSessionDelegate, UIGestureRecognizerDelegate {
//
//    let realm = try! Realm()
//    lazy var session: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
//    lazy var feeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
//    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
//
//    var trackingState = 0
//    var contentZoom: Double = 1
//    var updateTimer = Timer()
//    var updateInterval: Double = 10
//    var wordtrackError = false
//
//    var mainScene = SCNScene()
//
//    @IBOutlet var loadingView: UIView!
//
//
//    @IBAction func refreshBtnAction(_ sender: UIBarButtonItem) {
//        loadingView.isHidden = false
//
//        initScene()
//        updateScene()
//    }
//
//    @IBOutlet var sceneView: ARSCNView!
//
//
//    @IBAction func sharePhotoBtn(_ sender: UIBarButtonItem) {
//
//        let snapShot = sceneView.snapshot()
//        let imageToShare = [snapShot]
//        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
//        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook ]
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
//    func addContentToScene(contentObj: RLM_Obj, fPath: String, scaleFactor: Double) {
//        print("addContentToScene: " + String(contentObj.id))
//
//        var distanceScale: Double = 10000000 / scaleFactor
//        
//        let rawDeviceGpsCCL  = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)! )
//        let rawObjectGpsCCL  = CLLocation(latitude: contentObj.lat, longitude: contentObj.lng)
//        let objectAlt        = contentObj.alt
//        let objectDistance   = rawDeviceGpsCCL.distance(from: rawObjectGpsCCL)
//
//        if (session.first?.distanceScale)! {
//            distanceScale    = (objectDistance / scaleFactor) + 1000
//        }
//
//        let translation      = MatrixHelper.transformMatrix(for: matrix_identity_float4x4, originLocation: rawDeviceGpsCCL, location: rawObjectGpsCCL)
//        let translationSCNV  = SCNVector3.positionFromTransform(translation)
//
//        var latLongXyz = SCNVector3(0, 0, 0)
//
//        if (trackingState == 3) {
//            let objectXYZPos = ValConverters().gps_to_ecef( latitude: contentObj.lat, longitude: contentObj.lng, altitude: 0.01 )
//            let deviceXYZPos = ValConverters().gps_to_ecef( latitude: rawDeviceGpsCCL.coordinate.latitude, longitude: rawDeviceGpsCCL.coordinate.longitude, altitude: 0.01 )
//            let xPos         = (((objectXYZPos[0] - deviceXYZPos[0])) / distanceScale)
//            let yPos         = (((objectXYZPos[1] - deviceXYZPos[1])) / distanceScale)
//
//            latLongXyz       = SCNVector3(xPos, objectAlt, yPos)
//        } else {
//            let normalisedTrans  = CGPoint(x: Double(translationSCNV.x) / distanceScale, y: Double(translationSCNV.z) / distanceScale )
//            latLongXyz       = SCNVector3(normalisedTrans.x, CGFloat(objectAlt), normalisedTrans.y)
//        }
//
//        let node = ContentNode(title: contentObj.name, location: rawObjectGpsCCL)
//
//        if fPath != "" && contentObj.type.lowercased() != "text" {
//            print("Adding: " + contentObj.type.lowercased() + ": " + fPath)
//
//            if contentObj.type.lowercased() == "obj" {
//                node.addObj(fPath: fPath, contentObj: contentObj)
//                node.location = rawObjectGpsCCL
//                node.position = latLongXyz
//                mainScene.rootNode.addChildNode(node)
//            }
//
//            if contentObj.type.lowercased() == "usdz" {
//                node.addUSDZ(fPath: fPath, contentObj: contentObj, position: latLongXyz)
//                node.location = rawObjectGpsCCL
//                node.position = latLongXyz
//                mainScene.rootNode.addChildNode(node)
//            }
//
//            if contentObj.type.lowercased() == "image" {
//                node.addImage(fPath: fPath, contentObj: contentObj)
//                node.location = rawObjectGpsCCL
//                node.position = latLongXyz
//                mainScene.rootNode.addChildNode(node)
//            }
//
//            if contentObj.type.lowercased() == "gif" {
//                node.addGif(fPath: fPath, contentObj: contentObj)
//                node.location = rawObjectGpsCCL
//                node.position = latLongXyz
//                mainScene.rootNode.addChildNode(node)
//            }
//
//        } else {
//            if (contentObj.type.lowercased() == "text") {
//                node.addText(nodeText: contentObj.text, extrusion: 1, color: UIColor.black)
//                node.location = rawObjectGpsCCL
//                node.position = latLongXyz
//                mainScene.rootNode.addChildNode(node)
//            } else {
//                if (session.first?.showPlaceholders)! {
//                    let node = SCNNode(geometry: SCNSphere(radius: CGFloat(1) ))
//                    node.position = latLongXyz
//                    mainScene.rootNode.addChildNode(node)
//                }
//            }
//        }
//    }
//
//
//    func updateScene() {
//        print("Update Scene")
//
//        let curPos = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!)
//        let range = (session.first?.searchRadius)!
//
//        // TODO: Get search range
//        let objsInRange   = objectsInRange(position: curPos, useManualRange: true, manualRange: range)
//        let activeInRange = objsInRange.filter({$0.active && !$0.deleted})
//
//        for n in mainScene.rootNode.childNodes {
//            if (n.name != "DefaultAmbientLight") {
//                n.removeFromParentNode()
//            }
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
//                    addContentToScene(contentObj: o, fPath: (destinationUrl?.path)!, scaleFactor: (session.first?.scaleFactor)! )
//
//                } else {
//                    print("ERROR: FEED CONTENT: MISSING DATA: " + String(o.filePath))
//                }
//            } else {
//                if (o.type == "text") {
//                    addContentToScene(contentObj: o, fPath:"", scaleFactor: (session.first?.scaleFactor)! )
//                }
//            }
//        }
//
//    }
//
//
//    @objc func handleTap(rec: UITapGestureRecognizer){
//        if rec.state == .ended {
//            let location: CGPoint = rec.location(in: sceneView)
//            let hits = self.sceneView.hitTest(location, options: nil)
//
//            if let tappednode = hits.first?.node {
//                print(tappednode.name!)
//                print(tappednode.position)
//
//                if !tappednode.hasActions {
//                    //addHooverAnimation(node: tappednode)
//                    rotateAnimation(node: tappednode, xAmt: 0, yAmt: 1, zAmt: 0)
//                } else {
//                    tappednode.removeAllAnimations()
//                }
//
//            }
//        }
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
//
//        let configuration = ARWorldTrackingConfiguration()
//
//        configuration.planeDetection = [.vertical, .horizontal]
//        configuration.isAutoFocusEnabled = true
//        configuration.worldAlignment = .gravityAndHeading
//        configuration.isLightEstimationEnabled = true
//
//        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
//        sceneView.session.run(configuration)
//
//        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
//        sceneView.addGestureRecognizer(tapGestureRecognizer)
//        tapGestureRecognizer.cancelsTouchesInView = false
//    }
//
//
//    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
//        switch camera.trackingState {
//        case .notAvailable:
//            print("trackingState: not available")
//            trackingState = 2
//            loadingView.isHidden = false
//            updateScene()
//        case .limited(let reason):
//            print("trackingState: limited")
//            trackingState = 1
//            loadingView.isHidden = false
//            print(reason)
//        case .normal:
//            print("trackingState: normal")
//            trackingState = 0
//            loadingView.isHidden = true
//        }
//    }
//
//
//    @objc func handlePinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
//        guard gestureRecognizer.state != .ended else { return }
//
//        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
//            print(gestureRecognizer.scale)
//
//            for n in mainScene.rootNode.childNodes {
//                if (n.name != "DefaultAmbientLight") {
//                    n.scale = SCNVector3(
//                        Double(gestureRecognizer.scale),
//                        Double(gestureRecognizer.scale),
//                        Double(gestureRecognizer.scale))
//                }
//            }
//        }
//    }
//
//
//    @objc func mainTimerUpdate() {
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
//                    target: self, selector: #selector(mainTimerUpdate),
//                    userInfo: nil, repeats: true)
//            }
//        }
//
//        updateScene()
//    }
//
//
//    override func viewDidLoad() {
//        print("viewDidLoad")
//        loadingView.isHidden = false
//
//        let pinchGr = UIPinchGestureRecognizer(
//            target: self, action: #selector(ARViewer.handlePinch(_:))
//        )
//
//        pinchGr.delegate = self
//        view.addGestureRecognizer(pinchGr)
//    }
//
//
//    override func viewDidAppear(_ animated: Bool) {
//        print("viewDidAppear")
//        loadingView.isHidden = false
//
//        contentZoom = 0
//        updateScene()
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        print("viewWillAppear")
//        loadingView.isHidden = false
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        sceneView.session.pause()
//        loadingView.isHidden = false
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



















//    func rotatePoint(target: CGPoint, aroundOrigin origin: CGPoint, byDegrees: CGFloat) -> CGPoint {
//        let dx = target.x - origin.x
//        let dy = target.y - origin.y
//        let radius = sqrt(dx * dx + dy * dy)
//        let azimuth = atan2(dy, dx)
//        let newAzimuth = azimuth + byDegrees * CGFloat(.pi / 180.0)
//        let x = origin.x + radius * cos(newAzimuth)
//        let y = origin.y + radius * sin(newAzimuth)
//
//        return CGPoint(x: x, y: y)
//    }
//
//
//    func rotateLatLong(lat: Double, lon: Double, angle: Double, center: CGPoint) -> CGPoint {
//
//        let a = Double(center.x) + (cos(deg2rad(angle)))
//        let b = Double(center.y) + (sin(deg2rad(angle)))
//
//        let aa = Double(lat - Double(center.x)) - sin(deg2rad(angle))
//        let bb = Double(lat - Double(center.x)) - cos(deg2rad(angle))
//
//        let latR = a * aa * (lon - Double(center.y))
//        let lonR = b * bb * (lon - Double(center.y))
//
//        return CGPoint(x: latR, y: lonR)
//    }


//    func cclBearing(point1 : CLLocation, point2 : CLLocation) -> Double {
//        let x = point1.coordinate.longitude - point2.coordinate.longitude
//        let y = point1.coordinate.latitude  - point2.coordinate.latitude
//
//        return fmod(rad2deg(radians: atan2(y, x)), 360.0) + 90.0
//    }


//    func locationWithBearing(bearing:Double, distanceMeters:Double, origin:CLLocationCoordinate2D) -> CLLocationCoordinate2D {
//        let distRadians = distanceMeters / (6372797.6)
//
//        let lat1 = origin.latitude  * Double.pi / 180.0
//        let lon1 = origin.longitude * Double.pi / 180.0
//
//        let lat2 = asin(sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(bearing))
//        let lon2 = lon1 + atan2(sin(bearing) * sin(distRadians) * cos(lat1), cos(distRadians) - sin(lat1) * sin(lat2))
//
//        return CLLocationCoordinate2D(latitude: lat2 * 180 / Double.pi, longitude: lon2 * 180 / Double.pi)
//    }


//    static func translationMatrix_b(with matrix: matrix_float4x4, for translation : vector_float4) -> matrix_float4x4 {
//        var matrix = matrix
//        matrix.columns.3 = translation
//        return matrix
//    }
//
//
//    static func rotateAroundY_b(with matrix: matrix_float4x4, for degrees: Float) -> matrix_float4x4 {
//        var matrix : matrix_float4x4 = matrix
//
//        matrix.columns.0.x = cos(degrees)
//        matrix.columns.0.z = -sin(degrees)
//
//        matrix.columns.2.x = sin(degrees)
//        matrix.columns.2.z = cos(degrees)
//        return matrix.inverse
//    }
//
//
//    static func transformMatrix(for matrix: simd_float4x4, originLocation: CLLocation, location: CLLocation) -> simd_float4x4 {
//        let distance = Float(location.distance(from: originLocation))
//        let bearing = originLocation.bearingToLocationRadian(location)
//        let position = vector_float4(0.0, 0.0, -distance, 0.0)
//        let translationMatrix = translationMatrix_b(with: matrix_identity_float4x4, for: position)
//        let rotationMatrix = rotateAroundY_b(with: matrix_identity_float4x4, for: Float(bearing))
//        let transformMatrix = simd_mul(rotationMatrix, translationMatrix)
//        return simd_mul(matrix, transformMatrix)
//    }

//    func transformLatLong(from location: CLLocation, to landmark: CLLocation, furthestAnchorDistance: Float) -> simd_float4x4 {
//
//        // Calculate the displacement
//        let distance = location.distance(from: landmark)
//        let distanceTransform = simd_float4x4.translatingIdentity(x: 0, y: 0, z: -min(Float(distance), 1))
//
//        // Calculate the horizontal rotation
//        let rotation = Matrix.angle(from: location, to: landmark)
//
//        // Calculate the vertical tilt
//        let tilt = Matrix.angleOffHorizon(from: location, to: landmark)
//
//        // Apply the transformations
//        let tiltedTransformation = Matrix.rotateVertically(matrix: distanceTransform, around: tilt)
//        let completedTransformation = Matrix.rotateHorizontally(matrix: tiltedTransformation, around: -rotation)
//
//        return completedTransformation
//    }
    
