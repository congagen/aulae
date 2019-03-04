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
    
    var audioSource: SCNAudioSource!
    
    var trackingState = 0
    var contentZoom: Double = 1
    var updateTimer = Timer()
    var audioListener: SCNNode? { return mainScene.rootNode }

    var mainScene = SCNScene()
    var selectedNode: ContentNode? = nil
    var audioNodes: [ContentNode]? = nil

    var currentPlanes: [SCNNode]? = nil
    
    @IBOutlet var loadingViewLabel: UILabel!
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
    
    @IBOutlet var muteBarButton: UIBarButtonItem!
    
    @IBAction func muteToggleBtn(_ sender: UIBarButtonItem) {
         resetAudioNodes(mute: !(session.first?.muteAudio)!)
        
        if (session.first?.muteAudio)! {
            updateScene()
        }
    }
    
    
    func resetAudioNodes(mute: Bool) {
        print("resetAudioNodes")
        
        do {
            try realm.write {
                session.first?.muteAudio = mute
                print("Muted: " + (session.first?.muteAudio.description)!)
            }
        } catch {
            print("Error: \(error)")
        }
        
        if (session.first?.muteAudio)! {
            muteBarButton.image = UIImage(named: "mute_btn_a")
            
            for a in mainScene.rootNode.audioPlayers {
                a.audioSource?.volume = 0
            }
            
        } else {
            muteBarButton.image = UIImage(named: "mute_btn_b")
        }

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
    
    
    func addAudio(contentObj: RLM_Obj, objectDistance: Double, audioRangeRadius: Double, fPath: String, nodeSize: CGFloat) {
        if objectDistance < audioRangeRadius && !(session.first?.muteAudio)! {
            
            let urlPath = URL(fileURLWithPath: fPath)
            let asrc = SCNAudioSource(url: urlPath)
            asrc!.volume = Float(1.0 / objectDistance)
            asrc!.loops  = true
            asrc!.isPositional = true
            asrc!.load()
            
            mainScene.rootNode.addAudioPlayer(SCNAudioPlayer(source: asrc!))
        }
    }

    
    func addContentToScene(contentObj: RLM_Obj, fPath: String, scaleFactor: Double) {
        print("AddContentToScene: " + String(contentObj.id))
        print("Adding: " + contentObj.type.lowercased() + ": " + fPath)
        
        let audioRangeRadius: Double = 1000
        let rawDeviceGpsCCL   = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!)
        let rawObjectGpsCCL   = CLLocation(latitude: contentObj.lat, longitude: contentObj.lng)
        let objectDistance    = rawDeviceGpsCCL.distance(from: rawObjectGpsCCL)
        var nodeSize: CGFloat = 1
        var contentPos        = SCNVector3(contentObj.x_pos, contentObj.y_pos, contentObj.z_pos)
        
        if contentObj.world_position {
            contentPos = getNodeWorldPosition(baseOffset: 1.0, contentObj: contentObj, scaleFactor: scaleFactor)
        }
        if (session.first?.distanceScale)! && contentObj.world_scale {
            nodeSize = CGFloat( ( CGFloat(100 / (CGFloat(objectDistance) + 100) ) * CGFloat(objectDistance) ) / CGFloat(objectDistance) ) + CGFloat(0.1 / scaleFactor)
        }
        
        let ctNode = ContentNode(id: contentObj.id, title: contentObj.name, feedId: contentObj.feedId, location: rawObjectGpsCCL)
        ctNode.removeAllAudioPlayers()
        
        if fPath != "" && contentObj.type.lowercased() != "text" {

            if contentObj.type.lowercased() == "obj" {
                ctNode.addObj(fPath: fPath, contentObj: contentObj)
            }
            if contentObj.type.lowercased() == "usdz" {
                ctNode.addUSDZ(fPath: fPath, contentObj: contentObj)
            }
            if contentObj.type.lowercased() == "image" {
                ctNode.addImage(fPath: fPath, contentObj: contentObj)
            }
            if contentObj.type.lowercased() == "gif" {
                ctNode.addGif(fPath: fPath, contentObj: contentObj)
            }
            if contentObj.type.lowercased() == "audio" {
                if (session.first?.showPlaceholders)! {
                    ctNode.addSphere(radius: 0.025 + (nodeSize * 0.01), and: UIColor(hexColor: contentObj.hex_color))
                    addHooverAnimation(node: ctNode, distance: 0.1, speed: 1)
                }
                addAudio(contentObj: contentObj, objectDistance: objectDistance, audioRangeRadius: audioRangeRadius, fPath: fPath, nodeSize: nodeSize)
            }
        } else {
            if contentObj.type.lowercased() == "text" {
                ctNode.addText(
                    objText: contentObj.text, extrusion: CGFloat(contentObj.scale * 0.1),
                    fontSize: CGFloat(contentObj.scale), color: UIColor(hexColor: contentObj.hex_color)
                )
            }
        }
        
        ctNode.scale    = SCNVector3(nodeSize, nodeSize, nodeSize)
        ctNode.position = contentPos
        ctNode.tagComponents(nodeTag: contentObj.uuid)
        ctNode.name = contentObj.uuid
        
        if contentObj.style == 0 {
            let constraint = SCNBillboardConstraint()
            constraint.freeAxes = [.Y]
            ctNode.constraints = [constraint]
        }
        
        sceneView.scene.rootNode.addChildNode(ctNode)
    }
    
    
    func updateScene() {
        print("Update Scene")
        
        let curPos = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!)
        let range = (session.first?.searchRadius)!
        
        // TODO: Get search range
        let objsInRange   = objectsInRange(position: curPos, useManualRange: true, manualRange: range)
        let activeInRange = objsInRange.filter({$0.active && !$0.deleted})
        
        for n in mainScene.rootNode.childNodes {
            if !n.isKind(of: SKLightNode.self) && !n.isKind(of: ARCamera.self) && !n.isKind(of: SCNAudioPlayer.self) {
                n.removeAllActions()
                n.removeAllAnimations()
                n.removeFromParentNode()
            }
        }
        
        resetAudioNodes(mute: (session.first?.muteAudio)!)
        
        for o in activeInRange {
            print("Obj in range: " + o.name)
            
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
        print("handleTap")
        
        for n in mainScene.rootNode.childNodes {
            n.removeAllAnimations()
            n.removeAllActions()
            n.isHidden = false
        }
        
        if rec.state == .ended {

            let location: CGPoint = rec.location(in: sceneView)
            let hits = self.sceneView.hitTest(location, options: nil)
   
            if let tappedNode = hits.first?.node {
                let matchingObjs = feedObjects.filter({$0.uuid == tappedNode.name})
                
                if matchingObjs.count > 0 {
                    let sNodes = mainScene.rootNode.childNodes.filter( {$0.name == matchingObjs.first?.uuid} )
                    
                    for sn in sNodes {
                        if (sn.isKind(of: ContentNode.self)) {
                            
                            if selectedNode == (sNodes.first as! ContentNode) {
                                showSeletedNodeActions(objData: matchingObjs.first!)
                                highlightSelected(hideOther: true)

                            } else {
                                selectedNode = (sNodes.first as! ContentNode)
                                highlightSelected(hideOther: true)
                            }
                        }
                    }
                }
            } else {
                if (selectedNode != nil) {
                    selectedNode?.removeAllAnimations()
                }
                
                selectedNode = nil
                
            }
        }
    }
    
    
    @objc func handlePinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
        guard gestureRecognizer.state != .ended else { return }
        
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            print(gestureRecognizer.scale)
            
            for n in mainScene.rootNode.childNodes {
                if !n.isKind(of: SKLightNode.self) && !n.isKind(of: ARCamera.self) {
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
        var message: String = ""
        
        switch camera.trackingState {
        case .notAvailable:
            message = "Tracking error, try reloading the scene"
            trackingState = 2
            loadingView.isHidden = false
//            updateScene()
        case .normal:
            message = "Calibrating..."
            trackingState = 0
            loadingView.isHidden = true
//            endRelocalization()
        case .limited(.excessiveMotion):
            message = "Try slowing down your movement"
            trackingState = 1
            loadingView.isHidden = false
        case .limited(.insufficientFeatures):
            trackingState = 1
            message = "Try pointing at a flat surface or refreshing the scene"
        case .limited(.initializing):
            trackingState = 1
            message = "Calibrating..."
        case .limited(.relocalizing):
            trackingState = 2
//            beginRelocalization()
            message = "Calibrating..."
        }
        loadingViewLabel.text = message
    }
    
    
    
    func initScene() {
        print("initScene")
        loadingView.isHidden = false
        
        if (session.first?.muteAudio)! {
            muteBarButton.image = UIImage(named: "mute_btn_a")
            resetAudioNodes(mute: true)
        } else {
            muteBarButton.image = UIImage(named: "mute_btn_b")
        }
        
        mainScene = SCNScene(named: "art.scnassets/main.scn")!
        sceneView.scene = mainScene
        
        sceneView.session.delegate = self
        sceneView.delegate = self
        sceneView.audioListener = mainScene.rootNode
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical, .horizontal]
        configuration.isAutoFocusEnabled = true
        configuration.worldAlignment = .gravityAndHeading
        configuration.isLightEstimationEnabled = true
        configuration.maximumNumberOfTrackedImages = 99
        configuration.environmentTexturing = .automatic

        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.cancelsTouchesInView = false
    }
    
    
    private func optimizeCam() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }
        // Enable HDR camera settings for the most realistic appearance
        // with environmental lighting and physically based materials.
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = 0
        camera.maximumExposure = 1
    }
    
    
    override func viewDidLoad() {
        print("viewDidLoad")
        loadingView.isHidden = false

        let pinchGR = UIPinchGestureRecognizer(
            target: self, action: #selector(ARViewer.handlePinch(_:))
        )
        
        pinchGR.delegate = self
        view.addGestureRecognizer(pinchGR)
        optimizeCam()
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
        resetAudioNodes(mute: true)
        
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





//                if objectDistance < audioRangeRadius {
//                    let dupli = mainScene.rootNode.audioPlayers.filter( {$0.accessibilityLabel == contentObj.id} )
//
//                    if dupli.count != 0 {
//                        for d in dupli {
//                            mainScene.rootNode.removeAudioPlayer(d)
//                        }
//                    }
//
//                    let asrc = SCNAudioSource(url: URL(fileURLWithPath: fPath))
//                    asrc!.loops = true
//                    asrc?.isPositional = true
//                    asrc?.volume = Float(1.0 / objectDistance)
//                    asrc!.load()
//                    let player = SCNAudioPlayer(source: asrc!)
//                    player.accessibilityLabel = contentObj.id
//                    mainScene.rootNode.addAudioPlayer(player)
//
//                } else {
//                    print("Audiosource outside listener scope")
//                }






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
