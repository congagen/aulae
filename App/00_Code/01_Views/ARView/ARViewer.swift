//
//  ARViewer_.swift
//  aulae
//
//  Created by Tim Sandgren on 2019-02-11.
//  Copyright © 2019 Tim Sandgren. All rights reserved.

import Foundation
import CoreLocation
import ARKit
import Realm
import RealmSwift


class ARViewer: UIViewController, ARSCNViewDelegate, ARSessionDelegate, UIGestureRecognizerDelegate {
    
    lazy var realm = try! Realm()
    lazy var rlmSystem:      Results<RLM_SysSettings_117>    = {self.realm.objects(RLM_SysSettings_117.self)}()
    lazy var rlmSession:     Results<RLM_Session_117>        = {self.realm.objects(RLM_Session_117.self)}()
    lazy var rlmChatSession: Results<RLM_ChatSess>           = {self.realm.objects(RLM_ChatSess.self) }()

    lazy var rlmFeeds:       Results<RLM_Feed>               = {self.realm.objects(RLM_Feed.self)}()
    lazy var rlmSourceItems: Results<RLM_Obj>                = {self.realm.objects(RLM_Obj.self)}()
    lazy var rlmCamera:      Results<RLM_CameraSettings>     = {self.realm.objects(RLM_CameraSettings.self)}()
    
    var updateTimer = Timer()
    var sceneCameraSource: Any? = nil
    
    var isInit: Bool = false
    
//    var isTrackingQR = false
//    var qrUrl = ""
//    var qrCapturePreviewLayer: AVCaptureVideoPreviewLayer? = nil
//    var qrCaptureSession: AVCaptureSession? = nil
    
    var rawDeviceGpsCCL: CLLocation = CLLocation(latitude: 0, longitude: 0)
    var memoryWarning = false
    
    var trackingState = 3
    var configuration = ARWorldTrackingConfiguration()
    //var configuration = AROrientationTrackingConfiguration()
    
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
    
    @IBOutlet var startScreenLogo: UIView!
    
    
    @IBAction func showSettingsView(_ sender: UIBarButtonItem) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewController")
        vc!.modalPresentationStyle = .overFullScreen
        vc!.modalTransitionStyle = .crossDissolve
        
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
        // TODO Update FeedTVC
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
        print(view.bounds)
        print(sceneView.bounds)

        //ViewAnimation().fade(viewToAnimate: loadingView, aDuration: 1, hideView: false, aMode: .curveEaseIn)
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "QrViewController")
    
        vc!.definesPresentationContext = true

        vc!.modalPresentationStyle = .fullScreen
        vc!.modalTransitionStyle = .crossDissolve
        present(vc!, animated: false, completion: nil)
    }
    
    
    private func updateCameraSettings() {
        print("updateCameraSettings")
        
//        guard let camera = sceneView.pointOfView?.camera else {
//            fatalError("Expected a valid `pointOfView` from the scene.")
//        }
        
        sceneView.pointOfView?.camera!.wantsHDR       = true
        sceneView.pointOfView?.camera!.exposureOffset = CGFloat(rlmCamera.first!.exposureOffset)
        sceneView.pointOfView?.camera!.contrast       = 1 + CGFloat(rlmCamera.first!.contrast)
        sceneView.pointOfView?.camera!.saturation     = 1 + CGFloat(rlmCamera.first!.saturation)
        
        // guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        //let videoInput: AVCaptureDeviceInput
            
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
    
    
    func resetCameraToDefaultPosition() {
        sceneView.pointOfView?.position = SCNVector3(x: 5, y: 0, z: 5)
        sceneView.pointOfView?.orientation = SCNVector4(x: 0, y: 1, z: 0, w: .pi/4)
    }

    
    func report_memory() -> UInt64 {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            print("Memory used in bytes: \(taskInfo.resident_size)")
            return taskInfo.resident_size
        } else {
            print("Error with task_info(): " + (String(cString: mach_error_string(kerr), encoding: String.Encoding.ascii) ?? "unknown error"))
            return 0
        }
    }
    
    
    func checkNodeData(fPath: String, objData: RLM_Obj) -> Bool {
        var isOk = true
        
        if !(["", "text", "demo"].contains(objData.type)) && fPath != "" {
            if !FileManager.default.fileExists(atPath: URL(fileURLWithPath: fPath).path) {
                print("Missing ContentNode Data, Scheduling Retry...")
            
                isOk = false
            }
        }
                
        return isOk
    }
    
    
    func prepCustomTopicMarker(markerFilePath: String, objData: RLM_Obj, source: RLM_Feed) {
        print("prepCustomTopicMarker")
        
        let urlExt = (source.customMarkerUrl as NSString).pathExtension.lowercased()
        
        do {
            try realm.write {
                if FileManager.default.fileExists(atPath: URL(fileURLWithPath: source.customMarkerPath).path) {
                    print("prepCustomTopicMarker: Custom Marker File Exists")
                    
                    if (["gif"].contains(urlExt)){
                        objData.type = "gif"
                    }
                    if (["png", "jpg"].contains(urlExt)){
                        objData.type = "image"
                    }
                    if (["usdz"].contains(urlExt)){
                        objData.type = "usdz"
                    }
                    if (["mp3"].contains(urlExt)){
                        objData.type = "audio"
                    }
                    objData.customMarkerUrl = source.customMarkerUrl
                    objData.contentUrl = source.customMarkerUrl
                    objData.customMarkerPath = source.customMarkerPath
                } else {
                    print("CUSTOM MARKER ERR!")
                    print(source.customMarkerPath)
                    objData.type = "marker"
                }
                
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    
    func styledContentNode(objData: RLM_Obj, source: RLM_Feed, fPath: String, scaleFactor: Double, validData: Bool) -> ContentNode {
        let rawObjectGpsCCL   = CLLocation(latitude: objData.lat, longitude: objData.lng)
        let objectDistance    = rawDeviceGpsCCL.distance(from: rawObjectGpsCCL)
        var objectPos         = SCNVector3(objData.x_pos, objData.y_pos, objData.z_pos)
        var objSize           = SCNVector3(objData.scale, objData.scale, objData.scale)
        var nodeDatePath      = fPath
        
        if objData.world_position {
            objectPos = getNodeWorldPosition(
                objectDistance: objectDistance, baseOffset: 0.0,
                contentObj: objData, scaleFactor: scaleFactor
            )
        }
                        
        if source.customMarkerPath != "" {
            print("objData.customMarkerUrl != OK")
            
            prepCustomTopicMarker(markerFilePath: source.customMarkerPath, objData: objData, source: source)
            nodeDatePath = source.customMarkerPath
        }
        
        if (rlmSystem.first?.gpsScaling)! && objData.world_scale {
            let nSize = CGFloat((CGFloat(100 / (CGFloat(objectDistance) + 100)) * CGFloat(objectDistance)) / CGFloat(objectDistance)) + CGFloat(0.1 / scaleFactor)
            objSize = SCNVector3(nSize, nSize, nSize)
        } else {
            if (objData.type == "text" || objData.type == "audio" || objData.type == "marker") { objSize = SCNVector3(0.05, 0.05, 0.05) }
        }
        
        let ctNode = ContentNode(id: objData.uuid, title: objData.name, feedId: objData.feedId, info: objData.info, location: rawObjectGpsCCL)
        ctNode.setProp(source: source, objData: objData)
        
        if !validData && objData.type.lowercased() != "marker" {
            ctNode.addSphere(radius: 0.1, color: UIColor(hexColor: "cccccc"))
        } else {
            switch objData.type.lowercased() {
            case "particle":
                ctNode.addParticle(type: "", gravity: true)
            case "image":
                ctNode.addImage(fPath: nodeDatePath, objectData: objData)
            case "gif":
                ctNode.addGif(fPath: nodeDatePath, objectData: objData)
            case "obj":
                ctNode.addObj(fPath: nodeDatePath, objectData: objData)
            case "usdz":
                ctNode.addUSDZ(fPath: nodeDatePath, objectData: objData)
            case "text":
                ctNode.addText(objectData: objData, objText: objData.text, extrusion: CGFloat(objData.scale * 0.01), fontSize: 1, color: UIColor(hexColor: objData.hex_color))
            case "marker":
                ctNode.addSphere(radius: 1, color: UIColor(hexColor: objData.hex_color))
            case "demo":
                ctNode.addDemoContent( fPath: nodeDatePath, objectData: objData)
            case "audio":
                if !(rlmSystem.first?.muteAudio)! {
                    ctNode.addSphere(radius: CGFloat(1.0), color: UIColor(hexColor: objData.hex_color))
                    addAudio(contentObj: objData, objectDistance: objectDistance, audioRangeRadius: audioRangeRadius, fPath: fPath, nodeSize: CGFloat(objSize.x))
                }
            default:
                print("ok")
            }
            
        }
        
        if objData.billboard {
            let constraint      = SCNBillboardConstraint()
            constraint.freeAxes = [.Y]
            ctNode.constraints  = [constraint]
        }
                
        ctNode.name        = String(objData.uuid)
        
        // Handle y position random if set
        if source.da > 0.00001 {
            ctNode.position    = SCNVector3(objectPos.x, Float(Double.random(in: -source.da..<source.da)), objectPos.z)
        } else {
            ctNode.position    = SCNVector3(objectPos.x, objectPos.y, objectPos.z)
        }
        
        ctNode.scale       = objSize
        
        if objData.demo {
            //positionDemoNodes(ctNode: ctNode, objData: objData)
            ctNode.scale = SCNVector3(1, 1, 1)
        } else {
            if !objData.world_position && objData.localOrient {
                // TODO: Remove? let ori = sceneView.pointOfView?.orientation
                let qRotation = SCNQuaternion(0, 0, 0, 0)
                ctNode.rotate(by: qRotation, aroundTarget: (sceneView!.pointOfView?.position)!)
            }
        }
        
        ctNode.tagComponents(nodeTag: String(objData.uuid))
        
        return ctNode
    }
    
    
    func addSourceNode(objData: RLM_Obj, source: RLM_Feed, fPath: String, scaleFactor: Double) {
        print("AddContentToScene: " + String(objData.uuid))
        print("Adding: " + objData.type.lowercased() + ": " + fPath)

        var isIntact = true
        
        
        if objData.type == "marker" {
            if isIntact {
                isIntact = checkNodeData(fPath: source.customMarkerPath, objData: objData)
            }
        } else {
            if isIntact {
                isIntact = checkNodeData(fPath: fPath, objData: objData)
            }
        }
        
        
        if !objData.isInvalidated && !source.isInvalidated {
            if !memoryWarning {
                if Int(1000000000 * 0.5) > report_memory() {
                    let ctNode = styledContentNode(
                        objData: objData, source: source, fPath: fPath, scaleFactor: scaleFactor, validData: isIntact
                    )
                    sceneView.scene.rootNode.addChildNode(ctNode)
                } else {
                    showMemoryAlert()
                }
            } else {
                showMemoryAlert()
                memoryWarning = false
            }
            
        }
        
        
        func showMemoryAlert(){
            let alert =  UIAlertController(
                title: "Source Error",
                message: "\n" + "Memory limit exceeded, try disabling some sources",
                preferredStyle: UIAlertController.Style.alert
            )
            
            let act = UIAlertAction(title: "Done",  style: UIAlertAction.Style.default, handler: nil )
            
            if traitCollection.userInterfaceStyle == .light {
                alert.view.tintColor = UIColor.black
                act.setValue(UIColor.black, forKey: "titleTextColor")
            } else {
                alert.view.tintColor = UIColor.white
                act.setValue(UIColor.white, forKey: "titleTextColor")
            }
            
            alert.addAction(act)
            self.present(alert, animated: true, completion: nil)
        }
        
        
        
//        if isIntact {
//
//        } else {
//            Timer.scheduledTimer(
//                withTimeInterval: 2, repeats: false, block: {
//                    _ in DispatchQueue.main.async {
//                        if !objData.isInvalidated {
//                            self.addSourceNode(
//                                objData: objData, source: source,
//                                fPath: fPath, scaleFactor: scaleFactor
//                            )
//                        }
//                    }
//                }
//            )
//        }
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

                        let documentsUrl = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask).first! as NSURL
                        
                        let fileName = (URL(string: o.filePath)?.lastPathComponent)!
                        let destinationUrl = documentsUrl.appendingPathComponent(fileName)
                        
//                        DispatchQueue.main.async {
                        
                        self.addSourceNode(objData: o, source: objFeeds.first!, fPath: (
                            destinationUrl?.path)!, scaleFactor: (self.rlmSystem.first?.scaleFactor)!
                        )
//                        }
                        
                    } else {
                        if (o.type.lowercased() == "text") {
                            addSourceNode(
                                objData: o, source: objFeeds.first!, fPath: "",
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
        
        manageLoadingScreen(interval: 2)
    }
    
    
    func handleTap(touches: Set<UITouch>) {
        print("handleTap")
        loadingView.layer.opacity = 0
        startScreenLogo.isHidden = true
        
        if 1 == 3 {
//            TODO: Fix Stretch problem
//            isTrackingQR = false
//            view.reloadInputViews()
//            sceneView.reloadInputViews()
        } else {
            let location: CGPoint = touches.first!.location(in: sceneView)
            let hits = self.sceneView!.hitTest(location, options: [SCNHitTestOption.boundingBoxOnly: true])
            
            if touches.count < 2 {
                print(touches.count)
                if let tappedNode = hits.first?.node {
                    
                    let selno = sceneView.scene.rootNode.childNodes.filter({$0.name == tappedNode.name})
                    
                    if selno.count > 0 {
//                        if let ctno: ContentNode = (selno.first as? ContentNode) {
//                             if ctno.info != "" && ctno.contentLink != "" {
//                            if (ctno.directURL) && ((ctno.contentURL) != "") {
//                                self.openUrl(scheme: (ctno.contentURL))
//                            } else {
//                                showSeletedNodeActions(selNode: ctno)
//                            }
//                        }
                    }
                } else {
                    print("selectedNode = nil")
                    selectedNode = nil
                }
            }
        }
        
        do {
            try realm.write {
                if traitCollection.userInterfaceStyle == .light {
                    rlmSystem.first?.uiMode = 2
                } else {
                    rlmSystem.first?.uiMode = 1
                }
            }
        } catch {
            print("Error: \(error)")
        }
        UIOps().updateNavUiMode(navCtrl: self.navigationController!)
        UIOps().updateTabUIMode(tabCtrl: self.tabBarController!)
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
    

    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        print("handleLongPress")
        loadingView.layer.opacity = 0
        startScreenLogo.isHidden = true
        
        let location: CGPoint = gestureRecognizer.location(in: sceneView)
        let hits = self.sceneView!.hitTest(location, options: [SCNHitTestOption.boundingBoxOnly: true])

        if let tappedNode = hits.first?.node {
            let selno = sceneView.scene.rootNode.childNodes.filter({$0.name == tappedNode.name})
            
            if selno.count > 0 {
                if let ctno: ContentNode = (selno.first as? ContentNode) {

                    // if ctno.info != "" && ctno.contentLink != "" {
                    if (ctno.directURL) && ((ctno.contentURL) != "") {
                        self.openUrl(scheme: (ctno.contentURL))
                    } else {
                        showSeletedNodeActions(selNode: ctno)
                    }

                }
            }
        }
        
    }
    
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
        var message: String = ""
        trackingState = 2
        
        switch camera.trackingState {
            
        case .notAvailable:
            message = "state: notAvailable (updateCameraSettings)"
            updateCameraSettings()
            trackingState = 2
            
        case .normal:
            message = "state: normal"
            trackingState = 0
            
        case .limited(.excessiveMotion):
            message = "state: excessiveMotion"
            trackingState = 0
            
        case .limited(.insufficientFeatures):
            message = "state: insufficientFeatures"
            trackingState = 1
            
        case .limited(.initializing):
            trackingState = 1
            message = "state: initializing"

        case .limited(.relocalizing):
            trackingState = 2
            message = "state: relocalizing"
        case .limited(_):
            message = "state: relocalizing"
            message = "INITIALIZING"
        }
        
        print(message)
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
        
        if !startScreenLogo.isHidden {
            ViewAnimation().fade(
                viewToAnimate: self.startScreenLogo, aDuration: interval * 1.05,
                hideView: true, aMode: UIView.AnimationOptions.curveEaseIn
            )
        }
        
        do {
            try realm.write {
                if traitCollection.userInterfaceStyle == .light {
                    rlmSystem.first?.uiMode = 2
                } else {
                    rlmSystem.first?.uiMode = 1
                }
            }
        } catch {
            print("Error: \(error)")
        }
        UIOps().updateNavUiMode(navCtrl: self.navigationController!)
        UIOps().updateTabUIMode(tabCtrl: self.tabBarController!)
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

        if isInit {
            print("isInit == true")
            updateCameraSettings()
            initScene()
            //refreshScene()
        } else {
            print("isInit == false")
            FeedMgmt().updateFeeds(checkTimeSinceUpdate: false)
            Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: {_ in  self.initScene() })
            manageLoadingScreen(interval: 5)
            updateCameraSettings()
            isInit = true
        }
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad: ArView")
                
        let pinchGR = UIPinchGestureRecognizer(
            target: self, action: #selector(ARViewer.handlePinch(_:))
        )
        
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(MapVC.handleLongPress(_:)))
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        self.view.addGestureRecognizer(lpgr)
        
        pinchGR.delegate = self
        view.addGestureRecognizer(pinchGR)
        
//        for n in mainScene.rootNode.childNodes {
//            if let no: ContentNode = n as? ContentNode {
//                showSeletedNodeActions(selNode: no)
//            }
//        }

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

        //configuration.sceneReconstruction = .meshWithClassification
        configuration.planeDetection = [.vertical, .horizontal]
        
        configuration.isAutoFocusEnabled = true
        configuration.worldAlignment = .gravityAndHeading
        configuration.isLightEstimationEnabled = true
        
        configuration.automaticImageScaleEstimationEnabled = true
//        configuration.sceneReconstruction = .meshWithClassification
                
        sceneView.session.run(
            configuration, options: [.stopTrackedRaycasts, .resetSceneReconstruction, .resetTracking, .removeExistingAnchors])
        
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
                selector: #selector(mainTimerUpdate), userInfo: nil, repeats: true
            )
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
    
    
    override func didReceiveMemoryWarning() {
        memoryWarning = true
        // TODO: Alert? / Indicator
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
