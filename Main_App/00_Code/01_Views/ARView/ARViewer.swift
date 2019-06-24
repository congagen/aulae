//
//  ARViewer_.swift
//  aulae
//
//  Created by Tim Sandgren on 2019-02-11.
//  Copyright © 2019 Abstraqata. All rights reserved.

import Foundation
import CoreLocation
import ARKit
import Realm
import RealmSwift


class ARViewer: UIViewController, ARSCNViewDelegate, ARSessionDelegate, UIGestureRecognizerDelegate, AVCaptureMetadataOutputObjectsDelegate {
    
    let realm = try! Realm()
    lazy var rlmSystem:      Results<RLM_SysSettings_117>    = {self.realm.objects(RLM_SysSettings_117.self)}()
    lazy var rlmSession:     Results<RLM_Session_117>        = {self.realm.objects(RLM_Session_117.self)}()
    lazy var rlmChatSession: Results<RLM_ChatSess>       = {self.realm.objects(RLM_ChatSess.self) }()

    lazy var rlmFeeds:       Results<RLM_Feed>           = {self.realm.objects(RLM_Feed.self)}()
    lazy var rlmSourceItems: Results<RLM_Obj>            = {self.realm.objects(RLM_Obj.self)}()
    lazy var rlmCamera:      Results<RLM_CameraSettings> = {self.realm.objects(RLM_CameraSettings.self)}()
    
    var updateTimer = Timer()
    var sceneCameraSource: Any? = nil
    
    var isTrackingQR = false
    var qrUrl = ""
    var qrCapturePreviewLayer: AVCaptureVideoPreviewLayer? = nil
    var qrCaptureSession: AVCaptureSession? = nil
    
    var rawDeviceGpsCCL: CLLocation = CLLocation(latitude: 0, longitude: 0)

    var trackingState = 3
    var configuration = AROrientationTrackingConfiguration()
    
    var mainVC: MainVC? = nil
    var mainScene = SCNScene()
    var selectedNode: ContentNode? = nil
    let audioRangeRadius: Double = 1000
    
    var currentPlanes: [SCNNode]? = nil
    var selectedNodeChatUrl = ""
    //let progressBar = UIProgressView()
    
    let layerView: UIStoryboard! = nil
    let mapView: UIStoryboard! = nil
    let settingsView: UIStoryboard! = nil
    let chatView: UIStoryboard! = nil
    
    
    @IBAction func showSettingsView(_ sender: UIBarButtonItem) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewController")
        vc!.modalPresentationStyle = .overFullScreen
        vc!.modalTransitionStyle = .coverVertical
        
        present(vc!, animated: true, completion: nil)
    }
    
    func showChatView() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController")
        vc!.modalPresentationStyle = .overFullScreen
        vc!.modalTransitionStyle = .crossDissolve
        
        present(vc!, animated: true, completion: nil)
    }
    
    @IBOutlet var loadingView: UIView!
    @IBAction func refreshBtnAction(_ sender: UIBarButtonItem) {
        loadingView.isHidden = false
        loadingView.layer.opacity = 1
        FeedMgmt().updateFeeds(checkTimeSinceUpdate: false)
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { _ in  self.initScene() })
    }
    
    
    @IBOutlet var sceneView: ARSCNView!
    
    @IBAction func sharePhotoBtn(_ sender: UIBarButtonItem) {
        print("sharePhotoBtn")
        let snapShot = sceneView.snapshot()
        let imageToShare = [ snapShot ]
        
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        //activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook ]
        activityViewController.view.tintColor = UIColor.black
        activityViewController.view.tintColorDidChange()
        
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    
    @IBOutlet var searchQRBtn: UIButton!
    @IBAction func searchQrBtnAction(_ sender: UIBarButtonItem) {
        print("searchQrBtnAction")
    
        if isTrackingQR && (qrCapturePreviewLayer != nil) {
            if qrCaptureSession != nil {
                qrCaptureSession?.stopRunning()
                qrCaptureSession = nil
            }
    
            qrCapturePreviewLayer?.removeFromSuperlayer()
            isTrackingQR = false
            
            qrCapturePreviewLayer = nil
        } else {
            qrCapturePreviewLayer = AVCaptureVideoPreviewLayer()
            qrCaptureSession = AVCaptureSession()
            ViewAnimation().fade(viewToAnimate: loadingView, aDuration: 1, hideView: false, aMode: .curveEaseIn)
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: {_ in  self.captureQRCode() })
        }
    }
    
    
    private func updateCameraSettings() {
        print("updateCameraSettings")
        
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }
        
        camera.wantsHDR       = true
        camera.exposureOffset = CGFloat(rlmCamera.first!.exposureOffset)
        camera.contrast       = 1 + CGFloat(rlmCamera.first!.contrast)
        camera.saturation     = 1 + CGFloat(rlmCamera.first!.saturation)
//        camera.bloomIntensity = 0.5
//        camera.bloomThreshold = 0.8
    
        if rlmCamera.first!.isEnabled {
            // sceneView.scene.background.contents = UIColor.black
        } else {
            // sceneView.scene.background.contents = UIColor.black
        }
        
    }
    
    
    func objectsInRange(position: CLLocation, useManualRange: Bool, manualRange: Double) -> [RLM_Obj] {
        print("objectsInRange")
        var objList: [RLM_Obj] = []
        
        if (useManualRange) {
            objList = rlmSourceItems.filter(
                { (CLLocation(
                    latitude: $0.lat, longitude: $0.lng).distance(from: position) <= Double(manualRange)) })
        } else {
            objList = rlmSourceItems.filter(
                { (CLLocation(
                    latitude: $0.lat, longitude: $0.lng).distance(from: position) <= Double($0.radius))   })
        }
        
        return objList
    }
    
    
    func addAudio(contentObj: RLM_Obj, objectDistance: Double, audioRangeRadius: Double, fPath: String, nodeSize: CGFloat) {
        if objectDistance < audioRangeRadius {
            
            let urlPath = URL(fileURLWithPath: fPath)
            let asrc = SCNAudioSource(url: urlPath)
            
            if (rlmSystem.first?.muteAudio)! {
                asrc!.volume = 0
            } else {
                asrc!.volume = Float(1.0 / objectDistance)
            }
            
            asrc!.loops  = true
            asrc!.isPositional = true
            asrc!.load()
            
            mainScene.rootNode.addAudioPlayer(SCNAudioPlayer(source: asrc!))
        }
    }
    
    
    func defualtLatLong(objData: RLM_Obj){
        do {
            try realm.write {
                objData.lat = rlmSession.first!.currentLat
                objData.lng = rlmSession.first!.currentLng
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    
    
    func reloadNodeContent(contentType: String) {
        if contentType == "" {}
        
        if contentType == "" {}
        
        if contentType == "" {}
        
        if contentType == "" {}
        
        if contentType == "" {}
        
        if contentType == "" {}
        
        if contentType == "" {}
        
    }
    
    
    func addSourceNode(objData: RLM_Obj, source: RLM_Feed, fPath: String, scaleFactor: Double) {
        print("AddContentToScene: " + String(objData.uuid))
        print("Adding: " + objData.type.lowercased() + ": " + fPath)
        
        if !["", "marker", "text"].contains(objData.filePath) {
            // if file != EXISTS -> schedule retry and abort load
        }

        let rawObjectGpsCCL   = CLLocation(latitude: objData.lat, longitude: objData.lng)
        let objectDistance    = rawDeviceGpsCCL.distance(from: rawObjectGpsCCL)
        var objectPos         = SCNVector3(objData.x_pos, objData.y_pos, objData.z_pos)
        var objSize           = SCNVector3(objData.scale, objData.scale, objData.scale)
        
        if objData.world_position {
            objectPos = getNodeWorldPosition(
                objectDistance: objectDistance, baseOffset: 0.0,
                contentObj: objData, scaleFactor: scaleFactor
            )
        }
        
        if (rlmSystem.first?.gpsScaling)! && objData.world_scale {
            let nSize = CGFloat(( CGFloat(100 / (CGFloat(objectDistance) + 100) ) * CGFloat(objectDistance) ) / CGFloat(objectDistance) ) + CGFloat(0.1 / scaleFactor)
            objSize = SCNVector3(nSize, nSize, nSize)
        } else {
            if (objData.type == "text" || objData.type == "audio" || objData.type == "marker") { objSize = SCNVector3(0.05, 0.05, 0.05) }
        }
        
        let ctNode = ContentNode(id: objData.uuid, title: objData.name, feedId: objData.feedId, info: objData.info, location: rawObjectGpsCCL)
        ctNode.feedUrl     = source.sourceUrl
        ctNode.feedName    = source.name
        ctNode.feedTopic   = source.topicKwd
        ctNode.contentLink = objData.contentLink
        ctNode.directLink  = objData.directLink
        
        if fPath != "" && objData.type.lowercased() != "text" {
//             ***************************************************************
//             TODO Add loading indicator and schedule retry if not present
//             ***************************************************************
            
//            if objData.filePath != "" && objData.type.lowercased() != "marker" && objData.type.lowercased() != "audio" {
//                if objData.type.lowercased() == "loadingSpinner" { ctNode.addGif(fPath:   fPath, objectData: objData) }
//            } else {
//
//            }
            
            if objData.type.lowercased() == "demo"   { ctNode.addDemoContent( fPath: fPath, objectData: objData) }
            if objData.type.lowercased() == "obj"    { ctNode.addObj(fPath:   fPath, objectData: objData) }
            if objData.type.lowercased() == "usdz"   { ctNode.addUSDZ(fPath:  fPath, objectData: objData) }
            if objData.type.lowercased() == "image"  { ctNode.addImage(fPath: fPath, objectData: objData) }
            if objData.type.lowercased() == "gif"    { ctNode.addGif(fPath:   fPath, objectData: objData) }
            
            if objData.type.lowercased() == "marker" {
                let mR = 0.05 + CGFloat( (((objectDistance) + 1)) / ( (objectDistance) + 1) )
                ctNode.addSphere(radius: mR, and: UIColor(hexColor: objData.hex_color))
            }
            
            if objData.type.lowercased() == "audio" {
                ctNode.removeAllAudioPlayers()
                if !(rlmSystem.first?.muteAudio)! {
                    ctNode.addSphere(radius: 0.1, and: UIColor(hexColor: objData.hex_color))
                    addAudio( contentObj: objData, objectDistance: objectDistance, audioRangeRadius: audioRangeRadius, fPath: fPath, nodeSize: CGFloat(objSize.x) )
                }
            }
            
        } else {
            if objData.type.lowercased() == "text" {
                ctNode.addText(
                    objectData: objData, objText: objData.text, extrusion: CGFloat(objData.scale * 0.01),
                    fontSize: 1, color: UIColor(hexColor: objData.hex_color) )
            } else {
                ctNode.addSphere(radius: 0.01, and: UIColor.blue)
            }
        }
        
        if objData.billboard {
            let constraint      = SCNBillboardConstraint()
            constraint.freeAxes = [.Y]
            ctNode.constraints  = [constraint]
        }
    
        ctNode.name        = String(objData.uuid)
        ctNode.position    = SCNVector3(objectPos.x, objectPos.y, objectPos.z)
        ctNode.scale       = objSize
        
        if objData.demo {
            positionDemoNodes(ctNode: ctNode, objData: objData)
            ctNode.scale    = SCNVector3(1, 1, 1)
        } else {
            if !objData.world_position && objData.localOrient {
                let ori = sceneView.pointOfView?.orientation
                let qRotation = SCNQuaternion(ori!.x, ori!.y, ori!.z, ori!.w)
                ctNode.rotate(by: qRotation, aroundTarget: (sceneView!.pointOfView?.position)!)
            }
        }
    
        ctNode.tagComponents(nodeTag: String(objData.uuid))
        sceneView.scene.rootNode.addChildNode(ctNode)
    }
    
    
    func hideNodesWithId(nodeId:String) {
        print("hideNodesWithId")
        for n in mainScene.rootNode.childNodes {
            if n.isKind(of: ContentNode.self) {
                if let no: ContentNode = (n as? ContentNode) {
                    if no.feedId == nodeId {
                        n.removeFromParentNode()
                    }
                }
            }
        }
    }
    
    
    func refreshScene() {
        print("RefreshScene")
        loadingView.isHidden = false
        loadingView.layer.opacity = 1
        
        rawDeviceGpsCCL          = CLLocation(latitude: rlmSession.first!.currentLat, longitude: rlmSession.first!.currentLng)
        let curPos               = CLLocation(latitude: (rlmSession.first?.currentLat)!, longitude: (rlmSession.first?.currentLng)!)
        let range                = (rlmSystem.first?.searchRadius)!
        let objsInRange          = objectsInRange(position: curPos, useManualRange: true, manualRange: range)
        let activeObjectsInRange = objsInRange.filter({$0.active && !$0.deleted})
        
        for n in mainScene.rootNode.childNodes {
            if n.isKind(of: ContentNode.self) {
                n.removeFromParentNode()
            }
        }
        
        mainScene.rootNode.removeAllAudioPlayers()
        
        for o in activeObjectsInRange {
            let objFeeds = rlmFeeds.filter({$0.id == o.feedId})
            var inRange = true
            
            if o.radius != 0 {
                let cLoc = CLLocation(
                    latitude: (rlmSession.first?.currentLat)!, longitude: (rlmSession.first?.currentLng)!)
                let d = cLoc.distance(from: CLLocation(latitude: o.lat, longitude: o.lng))
                inRange = d < o.radius
            }
            
            if objFeeds.count > 0 {
                if (objFeeds.first?.active)! && inRange {
                    print("Obj in range: " + o.name)
                    if o.filePath != "" && o.type.lowercased() != "text" && o.type.lowercased() != "demo" {
                        print("UpdateScene: activeInRange: " + String(o.uuid))

                        let documentsUrl = FileManager.default.urls(
                            for: .documentDirectory, in: .userDomainMask).first! as NSURL
                        
                        let fileName = (URL(string: o.filePath)?.lastPathComponent)!
                        let destinationUrl = documentsUrl.appendingPathComponent(fileName)
                        
                        if (FileManager.default.fileExists(atPath: (destinationUrl?.path)! )) {
                            print("FileManager.default.fileExists")
                            addSourceNode(objData: o, source: objFeeds.first!, fPath: (
                                destinationUrl?.path)!, scaleFactor: (rlmSystem.first?.scaleFactor)! )
                        }
                    } else {
                        if (o.type.lowercased() == "text") {
                            addSourceNode(
                                objData: o, source: objFeeds.first!, fPath:"",
                                scaleFactor: (rlmSystem.first?.scaleFactor)! )
                        }
                        
                        if o.type == "demo" {
                            addSourceNode(
                                objData: o, source: objFeeds.first!, fPath: o.filePath,
                                scaleFactor: (rlmSystem.first?.scaleFactor)! )
                        }
                    }
                }
            }
        }
        
        do {
            try realm.write {
                rlmSession.first?.needsRefresh = false
            }
        } catch {
            print("Error: \(error)")
        }
        
        manageLoadingScreen(interval: 1)
        
    }
    
    
    func handleTap(touches: Set<UITouch>) {
        print("handleTap")
        loadingView.layer.opacity = 0
        
        if isTrackingQR {
            //searchQRBtn.tintColor = self.view.window?.tintColor
            qrCaptureSession?.stopRunning()
            qrCapturePreviewLayer?.isHidden = true
            qrCapturePreviewLayer?.removeFromSuperlayer()
            isTrackingQR = false
            
            qrCapturePreviewLayer = nil
            qrCaptureSession = nil
        } else {
            let location: CGPoint = touches.first!.location(in: sceneView)
            let hits = self.sceneView!.hitTest(location, options: [SCNHitTestOption.boundingBoxOnly: true])
            
            if touches.count < 2 {
                if let tappedNode = hits.first?.node {
                    
                    let selno = sceneView.scene.rootNode.childNodes.filter({$0.name == tappedNode.name})
                    
                    if selno.count > 0 {
                        if let ctno: ContentNode = (selno.first as? ContentNode) {
                            
                            // if ctno.info != "" && ctno.contentLink != "" {
                            if (ctno.directLink) && ((ctno.contentLink) != "") {
                                self.openUrl(scheme: (ctno.contentLink))
                            } else {
                                showSeletedNodeActions(selNode: ctno)
                            }
                            
                        } else {
                            print(tappedNode.name!)
                            print("Error")
                        }
                    }
                    
                } else {
                    print("selectedNode = nil")
                    selectedNode = nil
                }
            }
        }
    }
    
    
    public func clamp<T>(_ value: T, minValue: T, maxValue: T) -> T where T : Comparable {
        return min(max(value, minValue), maxValue)
    }
    
    
    @objc func handlePinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
        print("handlePinch")
        if gestureRecognizer.state == .changed {
            for n in mainScene.rootNode.childNodes {
                if n.isKind(of: ContentNode.self) {
                    
                    var scale: Float = 0
                    
                    if gestureRecognizer.scale < 1 {
                        scale = (Float(gestureRecognizer.scale) * 0.1) + ( -1 )
                        let newscalex = scale * n.scale.x
                        let newscaley = scale * n.scale.y
                        let newscalez = scale * n.scale.z
                        n.scale = SCNVector3(newscalex, -newscaley, newscalez)
                    } else {
                        scale = (Float(gestureRecognizer.scale) * 0.1) + 1
                        let newscalex = scale * n.scale.x
                        let newscaley = scale * n.scale.y
                        let newscalez = scale * n.scale.z
                        n.scale = SCNVector3(newscalex, newscaley, newscalez)
                    }
                }
            }
        } else {
            gestureRecognizer.scale = 1.0
        }
    }
    
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
        var message: String = ""
        trackingState = 2
        
        switch camera.trackingState {
        case .notAvailable:
            message = "LOCALIZING"
            trackingState = 2
            
        case .normal:
            message = "UPDATING"
            trackingState = 0
            
        case .limited(.excessiveMotion):
            message = "LOCALIZING"
            trackingState = 0
            
        case .limited(.insufficientFeatures):
            message = "UPDATING"
            trackingState = 1
            
        case .limited(.initializing):
            trackingState = 1
            message = "INITIALIZING"

        case .limited(.relocalizing):
            trackingState = 2
            message = "LOCALIZING"
        case .limited(_):
            message = "INITIALIZING"
        }
        
        print(message)
        
        // loadingViewLabel.text = message
    }
  
    
    func manageLoadingScreen(interval: Double) {
        print("manageLoadingScreen")
        self.loadingView.isHidden = false
        
        if rlmSession.first!.needsRefresh {
            ViewAnimation().fade(
                viewToAnimate: self.loadingView, aDuration: interval,
                hideView: false, aMode: UIView.AnimationOptions.curveEaseIn
            )
            
        } else {
            ViewAnimation().fade(
                viewToAnimate: self.loadingView, aDuration: interval,
                hideView: true, aMode: UIView.AnimationOptions.curveEaseIn
            )
            
        }
        
        if rlmSession.first!.needsRefresh {
            Timer.scheduledTimer(
                withTimeInterval: TimeInterval(interval), repeats: false,
                block: {_ in self.manageLoadingScreen(interval: interval + 0.1)
            })
        }
    }

    
    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear: Arview")
        UIOps().updateNavUiMode(navCtrl: self.navigationController!)
        
        loadingView.isHidden = false
        loadingView.layer.opacity = 1
        
        
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        print("viewDidDisappear: Arview")
        loadingView.layer.removeAllAnimations()
        loadingView.isHidden = false
        loadingView.layer.opacity = 1

        do {
            try realm.write {
                rlmSession.first?.needsRefresh = true
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        UIOps().updateNavUiMode(navCtrl: self.navigationController!)
        UIOps().updateTabUIMode(tabCtrl: self.tabBarController!)

//        if rlmSystem.first!.needsRefresh && self.isFirstResponder {
//            loadingView.isHidden = false
//            loadingView.layer.opacity = 1
//
//            do {
//                try realm.write {
//                    rlmSystem.first?.needsRefresh = false
//                }
//            } catch {
//                print("Error: \(error)")
//            }
//
//            refreshScene()
//            manageLoadingScreen(interval: 1)
//            updateCameraSettings()
//        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear: ArView")
        loadingView.isHidden = false
        loadingView.layer.opacity = 1
        
        do {
            try realm.write {
                rlmSession.first?.needsRefresh = true
            }
        } catch {
            print("Error: \(error)")
        }

        refreshScene()
        manageLoadingScreen(interval: 1)
        updateCameraSettings()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad: ArView")
        
        loadingView.isHidden = false
        loadingView.layer.opacity = 1
        sceneCameraSource = sceneView.scene.background.contents

        initScene()
        
        let pinchGR = UIPinchGestureRecognizer(
            target: self, action: #selector(ARViewer.handlePinch(_:))
        )
        
        pinchGR.delegate = self
        view.addGestureRecognizer(pinchGR)
    }
    
    
    func initScene() {
        print("ARScene initScene")
        loadingView.isHidden      = false
        loadingView.layer.opacity = 1
        
        UIOps().updateNavUiMode(navCtrl: self.navigationController!)

        updateCameraSettings()
        mainScene = sceneView.scene // SCNScene(named: "art.scnassets/main.scn")!
        
        sceneView.session.delegate = self
        sceneView.delegate         = self
        sceneView.audioListener    = mainScene.rootNode

        configuration.isAutoFocusEnabled = true
        configuration.worldAlignment = .gravityAndHeading
        configuration.isLightEstimationEnabled = true
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        rawDeviceGpsCCL = CLLocation(
            latitude:  rlmSession.first!.currentLat,
            longitude: rlmSession.first!.currentLng
        )
        
        Timer.scheduledTimer(
            withTimeInterval: rlmSystem.first!.mapUpdateInterval,
            repeats: false, block: {_ in self.mainTimerUpdate()}
        )
        
        refreshScene()
    }
    
    
    @objc func mainTimerUpdate() {
        print("ARViewer: mainTimerUpdate")
        var ref = false
        
        updateCameraSettings()
        
        if rlmSession.first!.shouldRefreshView && rlmSystem.first!.autoUpdate {
            print("rlmSession.first!.shouldRefreshView && rlmSession.first!.autoUpdate")
            for fo in rlmSourceItems {
                if (fo.active && !fo.deleted) {
                    if mainScene.rootNode.childNodes.filter( {$0.name == fo.uuid} ).count == 0 {
                        ref = true
                        print("mainUpdate: needsUpdate")
                    }
                }
            }
        }
        
        if ref {
            refreshScene()
        }
        
        updateTimer.invalidate()
        
        if !updateTimer.isValid {
            updateTimer = Timer.scheduledTimer(
                timeInterval: rlmSystem.first!.feedUpdateInterval, target: self,
                selector: #selector(mainTimerUpdate), userInfo: nil, repeats: true)
        }
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTap(touches: touches)
    }
    
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("ArViewer: sessionWasInterrupted")
    }
    
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("ArViewer: sessionInterruptionEnded")
    }
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("didFailWithError")
        print(error)
        print(error.localizedDescription)
        
        if error is ARError {
            print(error)
        }
    }
    
    
    func positionDemoNodes(ctNode: ContentNode, objData: RLM_Obj) {
        print("positionDemoNodes")
        
        do {
            try realm.write {
                objData.lat = rlmSession.first!.currentLat
                objData.lng = rlmSession.first!.currentLng
            }
        } catch {
            print("Error: \(error)")
        }
        
        let ori = sceneView.pointOfView?.orientation
        let qRotation = SCNQuaternion(ori!.x, ori!.y, ori!.z, ori!.w)
        ctNode.rotate(by: qRotation, aroundTarget: (sceneView!.pointOfView?.position)!)
        
        ctNode.position = SCNVector3(
            ctNode.position.x, 0, ctNode.position.z
        )
    }
    
}


// UIOps().showLogo(navCtrl: self.navigationController!, imageName: "Logo_B")



//    @IBAction func toggleMapAction(_ sender: UIButton) {
////        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MapViewController")
////        vc!.modalPresentationStyle = .overCurrentContext
////        vc!.modalTransitionStyle = .crossDissolve
////        present(vc!, animated: true, completion: nil)
//    }
//
//    @IBAction func toggleSettingsBtnAction(_ sender: UIButton) {
////        let vc = self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewController")
////        vc!.modalPresentationStyle = .overCurrentContext
////        vc!.modalTransitionStyle = .crossDissolve
////        present(vc!, animated: true, completion: nil)
//    }
//
//    @IBAction func toggleLibManager(_ sender: UIButton) {
////        let vc = self.storyboard?.instantiateViewController(withIdentifier: "LibViewController")
////        vc!.modalPresentationStyle = .overCurrentContext
////        vc!.modalTransitionStyle = .crossDissolve
////        present(vc!, animated: true, completion: nil)
//    }




//func debugChat() {
//    do {
//        try realm.write {
//            rlmChatSession.first?.sessionUUID = "debugsession"
//            rlmChatSession.first?.apiUrl      = "https://2hni7twyhl.execute-api.us-east-1.amazonaws.com/main/aulae-avr"
//            rlmChatSession.first?.agentName   = "Chaty Bot"
//            rlmChatSession.first?.agentId     = "Chaty Bot"
//        }
//    } catch {
//        print("Error: \(error)")
//    }
//
//    showChatView()
//}
