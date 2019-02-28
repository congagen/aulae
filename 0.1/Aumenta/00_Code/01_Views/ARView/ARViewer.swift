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
        let snapShot = sceneView.snapshot()
        let imageToShare = [snapShot]
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook ]
        
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    
    func objectsInRange(position: CLLocation, useManualRange: Bool, manualRange: Double) -> [RLM_Obj] {
        var objList: [RLM_Obj] = []
        
        if (useManualRange) {
            objList = feedObjects.filter({ (CLLocation(latitude: $0.lat, longitude: $0.lng).distance(from: position) <= Double(manualRange)) })
        } else {
            objList = feedObjects.filter({ (CLLocation(latitude: $0.lat, longitude: $0.lng).distance(from: position) <= Double($0.radius))   })
        }
        
        return objList
    }

    
    func getNodeWorldPosition(baseOffset: Double, contentObj: RLM_Obj, scaleFactor: Double) -> SCNVector3 {
        var xPos: Double = 0
        var yPos: Double = 0
        
        let rawDeviceGpsCCL  = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!)
        let rawObjectGpsCCL  = CLLocation(latitude: contentObj.lat, longitude: contentObj.lng)

        let translation      = MatrixHelper.transformMatrix(for: matrix_identity_float4x4, originLocation: rawDeviceGpsCCL, location: rawObjectGpsCCL)
        let translationSCNV  = SCNVector3.positionFromTransform(translation)
        
        let objectDistance   = rawDeviceGpsCCL.distance(from: rawObjectGpsCCL)
        var scaleDivider: Double = (10000000 / scaleFactor)
        
        if (session.first?.distanceScale)! { scaleDivider     = (objectDistance / scaleFactor) }
   
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

        var latLongXyz = SCNVector3(contentObj.x_pos, contentObj.y_pos, contentObj.z_pos)
        
        if contentObj.useWorldPosition { latLongXyz = getNodeWorldPosition(
                baseOffset: 1.0, contentObj: contentObj, scaleFactor: scaleFactor
            )
        }
       
        let rawObjectGpsCCL = CLLocation(latitude: contentObj.lat, longitude: contentObj.lng)

        if fPath != "" && contentObj.type.lowercased() != "text" {
            let ctNode = ContentNode(title: contentObj.name, location: rawObjectGpsCCL)

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
            
            ctNode.location = rawObjectGpsCCL
            
            mainScene.rootNode.addChildNode(ctNode)
            
            if contentObj.style == 0 {
                ctNode.constraints = [SCNBillboardConstraint()]
            }
            
        } else {
            if contentObj.type.lowercased() == "text" {
                print("TEXT")
                print(contentObj.text)
                
                var nText = "?" 
                
                if contentObj.text != "" {
                    nText = contentObj.text
                }
                
                let ctNode = ContentNode(title: contentObj.name, location: rawObjectGpsCCL)
                
                ctNode.addText(
                    nodeText: nText, extrusion: CGFloat(contentObj.scale * 0.1),
                    fontSize: CGFloat(contentObj.scale), color: (view.superview?.tintColor)!
                )
                
                ctNode.location = rawObjectGpsCCL
                ctNode.position = latLongXyz
                mainScene.rootNode.addChildNode(ctNode)
                
                if contentObj.style == 0 {
                    let constraint = SCNBillboardConstraint()
                    constraint.freeAxes = [.Y]
                    ctNode.constraints = [constraint]
                }
                
            } else {
                if (session.first?.showPlaceholders)! {
                    let node = SCNNode(geometry: SCNSphere(radius: CGFloat(1) ))
                    node.position = latLongXyz
                    mainScene.rootNode.addChildNode(node)
                }
            }
        }
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
            
            if o.filePath != "" && !(o.type == "text") {
                let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
                let fileName = (URL(string: o.filePath)?.lastPathComponent)!
                let destinationUrl = documentsUrl.appendingPathComponent(fileName)
                
                print("UpdateScene: activeInRange: " + String(o.id))
                
                if (FileManager.default.fileExists(atPath: (destinationUrl?.path)! )) {
                    print("FileManager.default.fileExists")
                    
                    addContentToScene(contentObj: o, fPath: (destinationUrl?.path)!, scaleFactor: (session.first?.scaleFactor)! )
                } else {
                    if o.type == "text" {
                        addContentToScene(contentObj: o, fPath: "", scaleFactor: (session.first?.scaleFactor)! )
                    } else {
                        // TODO: Increment Feed Error Count -> [If VAL > THRESH] -> feed.active = false
                        print("ERROR: FEED CONTENT: MISSING DATA: " + String(o.filePath))
                    }
 
                }
            } else {
                if (o.type == "text") {
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
    
    
    func initScene() {
        print("initScene")
        loadingView.isHidden = false

        mainScene = SCNScene(named: "art.scnassets/main.scn")!
        sceneView.scene = mainScene
        
        sceneView.session.delegate = self
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.debugOptions = [.showBoundingBoxes, .showSkeletons, .showConstraints, .showPhysicsFields, .showConstraints, .showCreases, .showFeaturePoints]
        
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
    
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
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
    
    
    func worldUpdate(anchors: [ARAnchor]) {

//        for a in anchors {
//            if let planeAnchor = a as? ARPlaneAnchor {
//            }
//
//            if let wallAnchor = a as? ARObjectAnchor {
//            }
//        }

    }
    
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let currentTransform = frame.camera.transform
        print(currentTransform)
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        plane.materials.first?.diffuse.contents = UIColor.green
        
        let planeNode = SCNNode(geometry: plane)
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        
        currentPlanes?.append(planeNode)
        node.addChildNode(planeNode)
    }
    

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {

        worldUpdate(anchors: anchors)
    }
    

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        worldUpdate(anchors: anchors)
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
        initScene()

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
        loadingView.isHidden = false
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

