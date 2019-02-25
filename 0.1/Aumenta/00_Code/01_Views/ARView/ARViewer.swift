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
    var updateInterval: Double = 10
    var wordtrackError = false
    
    var mainScene = SCNScene()
    
    @IBAction func refreshBtnAction(_ sender: UIBarButtonItem) {
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
    
    
    func addContentToScene(contentObj: RLM_Obj, fPath: String, scaleFactor: Double) {
        print("addContentToScene: " + String(contentObj.id))
        
        var distanceScale: Double = 10000000 / scaleFactor
        
        let rawDeviceGpsCCL  = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)! )
        let rawObjectGpsCCL  = CLLocation(latitude: contentObj.lat, longitude: contentObj.lng)
        let objectAlt        = contentObj.alt
        
        let objectDistance   = rawDeviceGpsCCL.distance(from: rawObjectGpsCCL)
        
        if (session.first?.distanceScale)! {
            distanceScale    = (objectDistance / scaleFactor) + 1000
        }
        
        let translation      = MatrixHelper.transformMatrix(for: matrix_identity_float4x4, originLocation: rawDeviceGpsCCL, location: rawObjectGpsCCL)
        let translationSCNV  = SCNVector3.positionFromTransform(translation)
        
        var latLongXyz = SCNVector3(0, 0, 0)
        
        if (trackingState == 3) {
            let objectXYZPos     = ValConverters().gps_to_ecef( latitude: contentObj.lat, longitude: contentObj.lng, altitude: 0.01 )
            let deviceXYZPos     = ValConverters().gps_to_ecef( latitude: rawDeviceGpsCCL.coordinate.latitude, longitude: rawDeviceGpsCCL.coordinate.longitude, altitude: 0.01 )
            let xPos = (((objectXYZPos[0] - deviceXYZPos[0])) / distanceScale)
            let yPos = (((objectXYZPos[1] - deviceXYZPos[1])) / distanceScale)

            latLongXyz       = SCNVector3(xPos, objectAlt, yPos)
        } else {
            let normalisedTrans  = CGPoint(x: Double(translationSCNV.x) / distanceScale, y: Double(translationSCNV.z) / distanceScale )
            latLongXyz       = SCNVector3(normalisedTrans.x, CGFloat(objectAlt), normalisedTrans.y)
        }

        print("Distance:     " + String(objectDistance))
        print("TrnsPos:      " + String(latLongXyz.x) + ", " + String(latLongXyz.y) + ", " + String(latLongXyz.z))
        
        if fPath != "" && contentObj.type.lowercased() != "text" {
            
            if contentObj.type.lowercased() == "obj" {
                print("ADDING OBJ TO SCENE: " + fPath)
                
                let node = ContentNode(title: contentObj.name, location: rawObjectGpsCCL)
                node.addObj(fPath: fPath, contentObj: contentObj)
                node.location = rawObjectGpsCCL
                node.position = latLongXyz
                mainScene.rootNode.addChildNode(node)
            }

            if contentObj.type.lowercased() == "usdz" {
                print("ADDING USDZ TO SCENE: " + fPath)
                
                let node = ContentNode(title: contentObj.name, location: rawObjectGpsCCL)
                node.addUSDZ(fPath: fPath, contentObj: contentObj, position: latLongXyz)
                node.location = rawObjectGpsCCL
                node.position = latLongXyz
                mainScene.rootNode.addChildNode(node)
            }
            
            if contentObj.type.lowercased() == "image" {
                print("ADDING IMAGE TO SCENE")
                
                let node = ContentNode(title: contentObj.name, location: rawObjectGpsCCL)
                node.addImage(fPath: fPath, contentObj: contentObj)
                node.location = rawObjectGpsCCL
                node.position = latLongXyz
                mainScene.rootNode.addChildNode(node)
            }
            
            if contentObj.type.lowercased() == "gif" {
                print("ADDING GIF TO SCENE")
                
                let node = ContentNode(title: contentObj.name, location: rawObjectGpsCCL)
                node.addGif(fPath: fPath, contentObj: contentObj)
                node.location = rawObjectGpsCCL
                node.position = latLongXyz
                mainScene.rootNode.addChildNode(node)
            }
            
        } else {
            if (contentObj.type.lowercased() == "text") {
                print("ADDING TEXT TO SCENE")
                
                let node = ContentNode(title: contentObj.name, location: rawObjectGpsCCL)
                node.addText(nodeText: contentObj.text, extrusion: 1, color: UIColor.black)
                node.location = rawObjectGpsCCL
                node.position = latLongXyz
                mainScene.rootNode.addChildNode(node)
            } else {
                // TODO: Add placeholder if allowed in settings
            }
        }
    }
    
    
    func updateScene() {
        print("Update Scene")
        
        let curPos = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!)
        let range = (session.first?.searchRadius)!
        
        // TODO:  Get search range
        let objsInRange   = objectsInRange(position: curPos, useManualRange: true, manualRange: range)
        let activeInRange = objsInRange.filter({$0.active && !$0.deleted})
        
        for n in mainScene.rootNode.childNodes {
            if (n.name != "DefaultAmbientLight") {
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
                    print("ERROR: FEED CONTENT: MISSING DATA: " + String(o.filePath))
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
                //do something with tapped object
                print(tappednode.name!)
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
        
        mainScene = SCNScene(named: "art.scnassets/main.scn")!
        sceneView.scene = mainScene
        
        sceneView.session.delegate = self
        sceneView.delegate = self
        sceneView.showsStatistics = false
        
        //let configuration = AROrientationTrackingConfiguration()
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = [.vertical, .horizontal]
        configuration.isAutoFocusEnabled = true
        configuration.worldAlignment = .gravityAndHeading
        configuration.isLightEstimationEnabled = true
    
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.cancelsTouchesInView = false
        
        //sceneView.session.run(configuration)
    }
    
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            trackingState = 2
            print("trackingState: not available")
            updateScene()
        case .limited(let reason):
            trackingState = 1
            print("trackingState: limited")
            print(reason)
        case .normal:
            trackingState = 0
            print("trackingState: normal")
        }
    }
    
    
    @objc func handlePinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
        guard gestureRecognizer.state != .ended else { return }
        
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            print(gestureRecognizer.scale)
            
            for n in mainScene.rootNode.childNodes {
                if (n.name != "DefaultAmbientLight") {
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
            if updateTimer.timeInterval != updateInterval {
                updateTimer.invalidate()
            }
            
            updateInterval = session.first!.feedUpdateInterval
            
            if !updateTimer.isValid {
                updateTimer = Timer.scheduledTimer(
                    timeInterval: updateInterval,
                    target: self, selector: #selector(mainTimerUpdate),
                    userInfo: nil, repeats: true)
            }
        }
        
        updateScene()
    }
    
    
    override func viewDidLoad() {
        print("viewDidLoad")
        
        let pinchGr = UIPinchGestureRecognizer(
            target: self, action: #selector(ARViewer.handlePinch(_:))
        )
        pinchGr.delegate = self
        view.addGestureRecognizer(pinchGr)
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear")
        contentZoom = 0
        updateScene()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear")
        initScene()
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

