//
//  ARViewer_.swift
//  Aumenta
//
//  Created by Tim Sandgren on 2019-02-11.
//  Copyright © 2019 Abstraqata. All rights reserved.

import Foundation
import CoreLocation
import ARKit
import Realm
import RealmSwift


extension UIColor {
    convenience init(hexColor: String) {
        let scannHex = Scanner(string: hexColor)
        var rgbValue: UInt64 = 0
        scannHex.scanLocation = 0
        scannHex.scanHexInt64(&rgbValue)
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
    }
}


class ARViewer: UIViewController, ARSCNViewDelegate, ARSessionDelegate, UIGestureRecognizerDelegate {
    
    let realm = try! Realm()
    lazy var session: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var feeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
    
    var trackingState = 0
    var contentZoom: Double = 1
    var updateTimer = Timer()
    
    var mainScene = SCNScene()
    var selectedNode = SCNNode()
    var currentPlanes: [SCNNode]? = nil
    
    @IBOutlet var loadingView: UIView!
    @IBAction func refreshBtnAction(_ sender: UIBarButtonItem) {
        loadingView.isHidden = false
        initScene()
        updateScene()
    }
    
    @IBOutlet var sceneView: ARSCNView!
    
    
    @IBAction func sharePhotoBtn(_ sender: UIBarButtonItem) {
        print("sharePhotoBtn")

        let snapShot = sceneView.snapshot()
        let imageToShare = [snapShot]
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook ]
        
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    
    func objectsInRange(position: CLLocation, useManualRange: Bool, manualRange: Double) -> [RLM_Obj] {
        print("objectsInRange")
        var objList: [RLM_Obj] = []
        
        if (useManualRange) {
            objList = feedObjects.filter({ (CLLocation(latitude: $0.lat, longitude: $0.lng).distance(from: position) <= Double(manualRange)) })
        } else {
            objList = feedObjects.filter({ (CLLocation(latitude: $0.lat, longitude: $0.lng).distance(from: position) <= Double($0.radius))   })
        }
        
        return objList
    }

    
    func getNodeWorldPosition(baseOffset: Double, contentObj: RLM_Obj, scaleFactor: Double) -> SCNVector3 {
        print("getNodeWorldPosition")
        
        let rawDeviceGpsCCL      = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!)
        let rawObjectGpsCCL      = CLLocation(latitude: contentObj.lat, longitude: contentObj.lng)
        let objectDistance       = rawDeviceGpsCCL.distance(from: rawObjectGpsCCL)
        var scaleDivider: Double = (10000000 / scaleFactor)

        let translation      = MatrixHelper.transformMatrix(for: matrix_identity_float4x4, originLocation: rawDeviceGpsCCL, location: rawObjectGpsCCL)
        let translationSCNV  = SCNVector3.positionFromTransform(translation)
        
        if (session.first?.distanceScale)! { scaleDivider = (objectDistance / scaleFactor) }
   
        var xPos: Double = 0
        var yPos: Double = 0
        
        if translationSCNV.x < 0 {
            xPos = Double(Double(translationSCNV.x) / scaleDivider) - baseOffset
        } else {
            xPos = Double(Double(translationSCNV.x) / scaleDivider) + baseOffset
        }
        
        if translationSCNV.z < 0 {
            yPos = Double(Double(translationSCNV.z) / scaleDivider) - baseOffset
        } else {
            yPos = Double(Double(translationSCNV.z) / scaleDivider) + baseOffset
        }

        let normalisedTrans  = CGPoint(x: xPos, y: yPos )
        let latLongXyz       = SCNVector3(normalisedTrans.x, CGFloat(contentObj.alt), normalisedTrans.y)
    
        return latLongXyz
    }
    
    
    func addContentToScene(contentObj: RLM_Obj, fPath: String, scaleFactor: Double) {
        print("AddContentToScene: " + String(contentObj.id))
        print("Adding: " + contentObj.type.lowercased() + ": " + fPath)
        
        let rawDeviceGpsCCL = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!)
        let rawObjectGpsCCL = CLLocation(latitude: contentObj.lat, longitude: contentObj.lng)
        let objectDistance  = rawDeviceGpsCCL.distance(from: rawObjectGpsCCL)
        var latLongXyz      = SCNVector3(contentObj.x_pos, contentObj.y_pos, contentObj.z_pos)
        let nodeSize        = CGFloat( ( CGFloat(100 / (CGFloat(objectDistance)+100) ) * CGFloat(objectDistance) ) / CGFloat(objectDistance) ) + CGFloat(0.1 / scaleFactor)

        if contentObj.useWorldPosition {
            latLongXyz = getNodeWorldPosition(baseOffset: 1.0, contentObj: contentObj, scaleFactor: scaleFactor)
        }
       
        let ctNode = ContentNode(title: contentObj.name, location: rawObjectGpsCCL)
        
        if fPath != "" && contentObj.type.lowercased() != "text" {

            if contentObj.type.lowercased() == "obj" {
                ctNode.addObj(fPath: fPath, contentObj: contentObj)
            }
            if contentObj.type.lowercased() == "usdz" {
                ctNode.addUSDZ(fPath: fPath, contentObj: contentObj, position: latLongXyz)
            }
            if contentObj.type.lowercased() == "image" {
                ctNode.addImage(fPath: fPath, contentObj: contentObj)
            }
            if contentObj.type.lowercased() == "gif" {
                ctNode.addGif(fPath: fPath, contentObj: contentObj)
            }
            
        } else {
            if contentObj.type.lowercased() == "text" {
                ctNode.addText(
                    contentObj: contentObj, extrusion: CGFloat(contentObj.scale * 0.1),
                    fontSize: 1,
                    color: UIColor(hexColor: contentObj.hex_color)
                )
            }
        }
        
        ctNode.scale = SCNVector3(nodeSize, nodeSize, nodeSize)
        ctNode.location = rawObjectGpsCCL
        ctNode.position = latLongXyz
        
        if contentObj.style == 0 {
            let constraint = SCNBillboardConstraint()
            constraint.freeAxes = [.Y]
            ctNode.constraints = [constraint]
        }
        
        mainScene.rootNode.addChildNode(ctNode)
    }
    
    
    func updateScene() {
        print("Update Scene")
        
        let curPos = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!)
        let range = (session.first?.searchRadius)!
        
        // TODO: Get search range
        let objsInRange   = objectsInRange(position: curPos, useManualRange: true, manualRange: range)
        let activeInRange = objsInRange.filter({$0.active && !$0.deleted})
        
        for n in mainScene.rootNode.childNodes {
            if (n.name != "DefaultAmbientLight") && n.name != "camera" {
                n.removeFromParentNode()
            }
        }
        
        for o in activeInRange {
            print("Obj in range: ")
            
            if o.filePath != "" && o.type.lowercased() != "text" {
                let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
                let fileName = (URL(string: o.filePath)?.lastPathComponent)!
                let destinationUrl = documentsUrl.appendingPathComponent(fileName)
                
                print("UpdateScene: activeInRange: " + String(o.id))
                
                if (FileManager.default.fileExists(atPath: (destinationUrl?.path)! )) {
                    print("FileManager.default.fileExists")
                    addContentToScene(contentObj: o, fPath: (destinationUrl?.path)!, scaleFactor: (session.first?.scaleFactor)! )
                } else {
                    // TODO: Increment Feed Error Count -> [If VAL > THRESH] -> feed.active = false
                    print("ERROR: FEED CONTENT: MISSING DATA: " + String(o.filePath))
                }
            } else {
                if (o.type.lowercased() == "text") {
                    addContentToScene(contentObj: o, fPath:"", scaleFactor: (session.first?.scaleFactor)! )
                }
            }
        }
    }
    
    
    @objc func handleTap(rec: UITapGestureRecognizer){
        if rec.state == .ended {
            let location: CGPoint = rec.location(in: sceneView)
            let hits = self.sceneView.hitTest(location, options: nil)
            
            if let tappednode = hits.first?.node {
                if tappednode.name != nil {
                    print(tappednode.name!)
                }
                
                print(tappednode.position)
                
                if !tappednode.hasActions {
                    //addHooverAnimation(node: tappednode)
                    rotateAnimation(node: tappednode, xAmt: 0, yAmt: 1, zAmt: 0)
                } else {
                    tappednode.removeAllAnimations()
                }
            }
        }
    }
    
    
    @objc func handlePinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
        guard gestureRecognizer.state != .ended else { return }
        
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            print(gestureRecognizer.scale)
            
            for n in mainScene.rootNode.childNodes {
                if (n.name != "DefaultAmbientLight") && n.name != "camera" {
                    n.scale = SCNVector3(
                        Double(gestureRecognizer.scale),
                        Double(gestureRecognizer.scale),
                        Double(gestureRecognizer.scale))
                }
            }
        }
    }
    
    
    @objc func mainTimerUpdate() {
        print("mainUpdate: ARViewer")
        
        if session.count > 0 {
            if updateTimer.timeInterval != session.first!.feedUpdateInterval {
                updateTimer.invalidate()
            }
            
            if !updateTimer.isValid {
                updateTimer = Timer.scheduledTimer(
                    timeInterval: session.first!.feedUpdateInterval,
                    target: self, selector: #selector(mainTimerUpdate),
                    userInfo: nil, repeats: true)
            }
        }
        
        updateScene()
    }
    
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("cameraDidChangeTrackingState")
        
        switch camera.trackingState {
        case .notAvailable:
            print("trackingState: not available")
            trackingState = 2
            loadingView.isHidden = false
            updateScene()
        case .limited(let reason):
            print("trackingState: limited")
            trackingState = 1
            loadingView.isHidden = false
            print(reason)
        case .normal:
            print("trackingState: normal")
            trackingState = 0
            loadingView.isHidden = true
        }
    }
    
    
    func initScene() {
        print("initScene")
        loadingView.isHidden = false
        
        mainScene = SCNScene(named: "art.scnassets/main.scn")!
        sceneView.scene = mainScene
        
        sceneView.session.delegate = self
        sceneView.delegate = self
        
//        sceneView.showsStatistics = true
//        sceneView.debugOptions = [
//            .showBoundingBoxes, .showSkeletons, .showConstraints,
//            .showPhysicsFields, .showConstraints, .showCreases, .showFeaturePoints
//        ]
        
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = [.vertical, .horizontal]
        configuration.isAutoFocusEnabled = true
        configuration.worldAlignment = .gravityAndHeading
        configuration.isLightEstimationEnabled = true
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.cancelsTouchesInView = false
    }
    
    
    override func viewDidLoad() {
        print("viewDidLoad")
        loadingView.isHidden = false

        let pinchGR = UIPinchGestureRecognizer(
            target: self, action: #selector(ARViewer.handlePinch(_:))
        )
        
        pinchGR.delegate = self
        view.addGestureRecognizer(pinchGR)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear")
        loadingView.isHidden = false

        contentZoom = 0
        
        initScene()
        updateScene()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear")
        loadingView.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
        loadingView.isHidden = false
    }
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("ArKit ViewerVC: didFailWithError")
        print(error)
    }
    
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("ArKit ViewerVC: sessionWasInterrupted")
    }
    
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("ArKit ViewerVC: sessionInterruptionEnded")
    }
    
    
}



//    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        let currentTransform = frame.camera.transform
//        print(currentTransform)
//    }


//    func worldUpdate(anchors: [ARAnchor]) {
//
//        for a in anchors {
//            if let planeAnchor = a as? ARPlaneAnchor {
//            }
//
//            if let wallAnchor = a as? ARObjectAnchor {
//            }
//        }
//
//    }

//    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
//        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
//        let width = CGFloat(planeAnchor.extent.x)
//        let height = CGFloat(planeAnchor.extent.z)
//        let plane = SCNPlane(width: width, height: height)
//
//        plane.materials.first?.diffuse.contents = UIColor.green
//
//        let planeNode = SCNNode(geometry: plane)
//        let x = CGFloat(planeAnchor.center.x)
//        let y = CGFloat(planeAnchor.center.y)
//        let z = CGFloat(planeAnchor.center.z)
//
//        planeNode.position = SCNVector3(x,y,z)
//        planeNode.eulerAngles.x = -.pi / 2
//
//        currentPlanes?.append(planeNode)
//        node.addChildNode(planeNode)
//    }
//
//
//    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
//        worldUpdate(anchors: anchors)
//    }
//
//
//    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
//        worldUpdate(anchors: anchors)
//    }
