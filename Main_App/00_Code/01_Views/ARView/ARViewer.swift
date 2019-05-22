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
    lazy var rlmSystem:      Results<RLM_System>  = { self.realm.objects(RLM_System.self) }()
    lazy var rlmSession:     Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var rlmFeeds:       Results<RLM_Feed>    = { self.realm.objects(RLM_Feed.self) }()
    lazy var rlmSourceItems: Results<RLM_Obj>     = { self.realm.objects(RLM_Obj.self) }()
    lazy var rlmCamera:      Results<RLM_Camera>  = { self.realm.objects(RLM_Camera.self) }()

    var updateTimer = Timer()
    
    var isTrackingQR = false
    var qrUrl = ""
    var qrCapturePreviewLayer = AVCaptureVideoPreviewLayer()
    var qrCaptureSession = AVCaptureSession()
    
    var rawDeviceGpsCCL: CLLocation = CLLocation(latitude: 0, longitude: 0)

    var trackingState = 3
    var configuration = AROrientationTrackingConfiguration()
    
    var mainScene = SCNScene()
    var selectedNode: ContentNode? = nil
    let audioRangeRadius: Double = 1000
    
    var currentPlanes: [SCNNode]? = nil
    let progressBar = UIProgressView()
    
    @IBOutlet var MapViewCV: UIView!
    @IBOutlet var settingsCv: UIView!
    
    @IBAction func toggleMapAction(_ sender: UIButton) {
        ViewAnimation().fade(
            viewToAnimate: self.MapViewCV,
            aDuration: 0.25,
            hideView: false,
            aMode: UIView.AnimationOptions.curveEaseIn
        )
        
        MapViewCV.isUserInteractionEnabled = true
        closeBtn.isHidden = false
    }
    
    @IBAction func toggleSettingsBtnAction(_ sender: UIButton) {
        ViewAnimation().fade(
            viewToAnimate: self.settingsCv,
            aDuration: 0.25,
            hideView: false,
            aMode: UIView.AnimationOptions.curveEaseIn
        )
        
        settingsCv.isUserInteractionEnabled = true
        closeBtn.isHidden = false
    }
    
    @IBOutlet var closeBtn: UIButton!
    
    @IBAction func closeCvBtnAction(_ sender: UIButton) {
        closeBtn.isHidden = true
        
        ViewAnimation().fade(
            viewToAnimate: self.MapViewCV,
            aDuration: 0.25,
            hideView: true,
            aMode: UIView.AnimationOptions.curveEaseIn
        )
        
        MapViewCV.isUserInteractionEnabled = false
        
        ViewAnimation().fade(
            viewToAnimate: self.settingsCv,
            aDuration: 0.25,
            hideView: true,
            aMode: UIView.AnimationOptions.curveEaseIn
        )
        
        MapViewCV.isUserInteractionEnabled = false
        
        if rlmSystem.first!.needsRefresh {
            loadingView.isHidden = false
            initScene()
            Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: {_ in self.refreshScene() })
            
            do {
                try realm.write {
                    rlmSystem.first?.needsRefresh = false
                }
            } catch {
                print("Error: \(error)")
            }
        }

        
    }
    
    @IBOutlet var loadingView: UIView!
    
    @IBAction func refreshBtnAction(_ sender: UIButton) {
        loadingView.isHidden = false
        // NavBarOps().showProgressBar(navCtrl: self.navigationController!, progressBar: progressBar, view: self.view, timeoutPeriod: 1)

        // FeedMgmt().updateFeeds(checkTimeSinceUpdate: false)
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: {_ in self.initScene() })
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: {_ in self.refreshScene() })
        //initScene

    }
    
    @IBOutlet var sceneView: ARSCNView!
    
    
    @IBAction func sharePhotoBtn(_ sender: UIButton) {
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
    @IBAction func searchQrBtnAction(_ sender: UIButton) {
        print("searchQrBtnAction")
    
        if isTrackingQR {
            searchQRBtn.tintColor = self.view.window?.tintColor
            qrCaptureSession.stopRunning()
            qrCapturePreviewLayer.removeFromSuperlayer()
            isTrackingQR = false
        } else {
            
            ViewAnimation().fade(viewToAnimate: loadingView, aDuration: 0.5, hideView: false, aMode: .curveEaseIn)
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: {_ in  self.captureQRCode() })
            
            //captureQRCode()
            searchQRBtn.tintColor = UIColor.green
        }
    }
    
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
    }
    
    
    private func updateCameraSettings() {
        print("updateCameraSettings")
        
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }
        // Enable HDR camera settings for the most realistic appearance with environmental lighting and physically based materials.
        camera.wantsHDR       = true
        camera.exposureOffset = CGFloat(rlmCamera.first!.exposureOffset)
        camera.contrast       = 1 + CGFloat(rlmCamera.first!.contrast)
        camera.saturation     = 1 + CGFloat(rlmCamera.first!.saturation)
    }
    
    
    func objectsInRange(position: CLLocation, useManualRange: Bool, manualRange: Double) -> [RLM_Obj] {
        print("objectsInRange")
        var objList: [RLM_Obj] = []
        
        if (useManualRange) {
            objList = rlmSourceItems.filter({ (CLLocation(latitude: $0.lat, longitude: $0.lng).distance(from: position) <= Double(manualRange)) })
        } else {
            objList = rlmSourceItems.filter({ (CLLocation(latitude: $0.lat, longitude: $0.lng).distance(from: position) <= Double($0.radius))   })
        }
        
        return objList
    }
    
    
    func addAudio(contentObj: RLM_Obj, objectDistance: Double, audioRangeRadius: Double, fPath: String, nodeSize: CGFloat) {
        if objectDistance < audioRangeRadius {
            
            let urlPath = URL(fileURLWithPath: fPath)
            let asrc = SCNAudioSource(url: urlPath)
            
            if (rlmSession.first?.muteAudio)! {
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
    
    
    func insertSourceObject(objData: RLM_Obj, source: RLM_Feed, fPath: String, scaleFactor: Double) {
        print("AddContentToScene: " + String(objData.uuid))
        print("Adding: " + objData.type.lowercased() + ": " + fPath)

        let rawObjectGpsCCL   = CLLocation(latitude: objData.lat, longitude: objData.lng)
        let objectDistance    = rawDeviceGpsCCL.distance(from: rawObjectGpsCCL)
        var objectPos         = SCNVector3(objData.x_pos, objData.y_pos, objData.z_pos)
        var objSize           = SCNVector3(objData.scale, objData.scale, objData.scale)
        
        if objData.world_position {
            objectPos = getNodeWorldPosition(objectDistance: objectDistance, baseOffset: 0.0, contentObj: objData, scaleFactor: scaleFactor)
        }
        
        if (rlmSession.first?.distanceScale)! && objData.world_scale {
            let nSize = CGFloat(( CGFloat(100 / (CGFloat(objectDistance) + 100) ) * CGFloat(objectDistance) ) / CGFloat(objectDistance) ) + CGFloat(0.1 / scaleFactor)
            objSize = SCNVector3(nSize, nSize, nSize)
        } else {
            if (objData.type == "text" || objData.type == "audio" || objData.type == "marker") { objSize = SCNVector3(0.05, 0.05, 0.05) }
        }
        
        let ctNode = ContentNode(id: objData.uuid, title: objData.name, feedId: objData.feedId, info: objData.info, location: rawObjectGpsCCL)
        ctNode.feedUrl   = source.sourceUrl
        ctNode.feedName  = source.name
        ctNode.feedTopic = source.topicKwd
        ctNode.contentLink = objData.contentLink
        ctNode.directLink  = objData.directLink
        
        if fPath != "" && objData.type.lowercased() != "text" {
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
                if !(rlmSession.first?.muteAudio)! {
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
        
        rawDeviceGpsCCL          = CLLocation(latitude: rlmSession.first!.currentLat, longitude: rlmSession.first!.currentLng)
        let curPos               = CLLocation(latitude: (rlmSession.first?.currentLat)!, longitude: (rlmSession.first?.currentLng)!)
        let range                = (rlmSession.first?.searchRadius)!
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
                let cLoc = CLLocation(latitude:  (rlmSession.first?.currentLat)!, longitude: (rlmSession.first?.currentLng)!)
                let d = cLoc.distance(from: CLLocation(latitude: o.lat, longitude: o.lng))
                inRange = d < o.radius
            }
            
            if objFeeds.count > 0 {
                if (objFeeds.first?.active)! && inRange {
                    print("Obj in range: " + o.name)
                    if o.filePath != "" && o.type.lowercased() != "text" && o.type.lowercased() != "demo" {
                        print("UpdateScene: activeInRange: " + String(o.uuid))

                        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
                        let fileName = (URL(string: o.filePath)?.lastPathComponent)!
                        let destinationUrl = documentsUrl.appendingPathComponent(fileName)
                        
                        if (FileManager.default.fileExists(atPath: (destinationUrl?.path)! )) {
                            print("FileManager.default.fileExists")
                            insertSourceObject(objData: o, source: objFeeds.first!, fPath: (destinationUrl?.path)!, scaleFactor: (rlmSession.first?.scaleFactor)! )
                        }
                    } else {
                        if (o.type.lowercased() == "text") {
                            insertSourceObject(objData: o, source: objFeeds.first!, fPath:"", scaleFactor: (rlmSession.first?.scaleFactor)! )
                        }
                        
                        if o.type == "demo" {
                            insertSourceObject( objData: o, source: objFeeds.first!, fPath: o.filePath, scaleFactor: (rlmSession.first?.scaleFactor)! )
                        }
                    }
                }
            }
        }
        
        updateCameraSettings()
        
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: {_ in self.loadingView.isHidden = self.trackingState == 0 })
    }
    
    
    func handleTap(touches: Set<UITouch>) {
        print("handleTap")
        loadingView.isHidden = true
        
        if isTrackingQR {
            searchQRBtn.tintColor = self.view.window?.tintColor
            qrCaptureSession.stopRunning()
            qrCapturePreviewLayer.isHidden = true
            qrCapturePreviewLayer.removeFromSuperlayer()
            isTrackingQR = false
        } else {
            if MapViewCV.isHidden && settingsCv.isHidden {
                let location: CGPoint = touches.first!.location(in: sceneView)
                let hits = self.sceneView.hitTest(location, options: nil)
                
                if touches.count < 2 {
                    if let tappedNode = hits.first?.node {
                        //let matchingObjs = rlmSourceItems.filter( { $0.uuid == tappedNode.name } )
                        print(tappedNode)
                        print(tappedNode.name!)
                        
                        let selno = sceneView.scene.rootNode.childNodes.filter({$0.name == tappedNode.name})
                        
                        if selno.count > 0 {
                            if let ctno: ContentNode = (selno.first as? ContentNode) {
                                
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
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTap(touches: touches)
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

//        loadingViewLabel.text = message
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: {_ in self.loadingView.isHidden = self.trackingState == 0 })
    }
    
    
    func initScene() {
        print("ARScene initScene")
        loadingView.isHidden  = false

        searchQRBtn.tintColor = self.view.window?.tintColor
        
        mainScene = SCNScene(named: "art.scnassets/main.scn")!
        sceneView.scene = mainScene
        
        sceneView.session.delegate = self
        sceneView.delegate = self
        sceneView.audioListener = mainScene.rootNode
        
        configuration.isAutoFocusEnabled = true
        configuration.worldAlignment = .gravityAndHeading
        configuration.isLightEstimationEnabled = true

        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        rawDeviceGpsCCL = CLLocation(latitude: rlmSession.first!.currentLat, longitude: rlmSession.first!.currentLng)
        
        if (rlmSession.first?.autoUpdate)! {
            Timer.scheduledTimer(withTimeInterval: rlmSession.first!.mapUpdateInterval, repeats: false, block: {_ in self.mainTimerUpdate() })
        }
        
        updateCameraSettings()
    }
    
    
    @objc func mainTimerUpdate() {
        print("mainUpdate: ARViewer")
        var ref = false
        
        updateCameraSettings()
        
        if rlmSession.first!.shouldRefreshView && rlmSession.first!.autoUpdate {
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
                timeInterval: rlmSession.first!.feedUpdateInterval, target: self,
                selector: #selector(mainTimerUpdate), userInfo: nil, repeats: true)
        }
        
        Timer.scheduledTimer(
            withTimeInterval: 2, repeats: false, block: {_ in self.loadingView.isHidden = self.trackingState == 0 }
        )
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        // NavBarOps().showLogo(navCtrl: self.navigationController!, imageName: "Logo.png")

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
        initScene()
        
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: {_ in self.refreshScene() })
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear")
        progressBar.removeFromSuperview()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        loadingView.isHidden = false
        sceneView.session.pause()
        progressBar.removeFromSuperview()
    }
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("didFailWithError")
        print(error)
        print(error.localizedDescription)
        
//        if error is ARError {
//            initScene()
//        }
    }
    
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("ArKit ViewerVC: sessionWasInterrupted")
    }
    
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("ArKit ViewerVC: sessionInterruptionEnded")
    }
    
    

    
    
}
