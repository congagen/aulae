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
    lazy var rlmSession: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var rlmFeeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
    
    var updateTimer = Timer()
    
    var isInit = false
    var isTrackingQR = false
    var qrUrl = ""
    var qrCapturePreviewLayer = AVCaptureVideoPreviewLayer()
    var qrCaptureSession = AVCaptureSession()
    
    var trackingState = 3
    var configuration = AROrientationTrackingConfiguration()
    
    var mainScene = SCNScene()
    var selectedNode: ContentNode? = nil
    let audioRangeRadius: Double = 1000
    
    var currentPlanes: [SCNNode]? = nil
    let progressBar = UIProgressView()
    
    @IBOutlet var loadingViewLabel: UILabel!
    @IBOutlet var loadingView: UIView!
    @IBAction func refreshBtnAction(_ sender: UIBarButtonItem) {
        loadingView.isHidden = false
        FeedMgmt().updateFeeds(checkTimeSinceUpdate: false)
        NavBarOps().showProgressBar(navCtrl: self.navigationController!, progressBar: progressBar, view: self.view, timeoutPeriod: 1)
        mainTimerUpdate()
    }
    
    @IBOutlet var sceneView: ARSCNView!
    @IBAction func sharePhotoBtn(_ sender: UIBarButtonItem) {
        print("sharePhotoBtn")
        let snapShot = sceneView.snapshot()
        let imageToShare = [snapShot]
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        
        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook ]
        activityViewController.view.tintColor = UIColor.black

        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    
    @IBOutlet var searchQRBtn: UIBarButtonItem!
    @IBAction func searchQrBtnAction(_ sender: UIBarButtonItem) {
        print("searchQrBtnAction")
    
        if isTrackingQR {
            searchQRBtn.tintColor = self.view.window?.tintColor
            qrCaptureSession.stopRunning()
            qrCapturePreviewLayer.removeFromSuperlayer()
            isTrackingQR = false
        } else {
            isTrackingQR = true
            captureQRCode()
            searchQRBtn.tintColor = UIColor.green
        }
    }
    
    
    private func optimizeCam() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }
        // Enable HDR camera settings for the most realistic appearance with environmental lighting and physically based materials.
        camera.wantsHDR = true
        //camera.exposureOffset = 0
        camera.minimumExposure = 0
        camera.maximumExposure = 1
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
  
    
    func addContentToScene(contentObj: RLM_Obj, fPath: String, scaleFactor: Double, localDemoContent: Bool) {
        print("AddContentToScene: " + String(contentObj.uuid))
        print("Adding: " + contentObj.type.lowercased() + ": " + fPath)

        let rawDeviceGpsCCL   = CLLocation(latitude: (rlmSession.first?.currentLat)!, longitude: (rlmSession.first?.currentLng)!)
        let rawObjectGpsCCL   = CLLocation(latitude: contentObj.lat, longitude: contentObj.lng)
        let objectDistance    = rawDeviceGpsCCL.distance(from: rawObjectGpsCCL)
        var contentPos        = SCNVector3( contentObj.x_pos, contentObj.y_pos, contentObj.z_pos )
        
        print(contentPos)
        
        if contentObj.world_position {
            contentPos = getNodeWorldPosition(baseOffset: 0.0, contentObj: contentObj, scaleFactor: scaleFactor)
        }
        
        var nodeSize: CGFloat = CGFloat(1 * contentObj.scale)
        if (rlmSession.first?.distanceScale)! && contentObj.world_scale {
            nodeSize = CGFloat(( CGFloat(100 / (CGFloat(objectDistance) + 100) ) * CGFloat(objectDistance) ) / CGFloat(objectDistance) ) + CGFloat(0.1 / scaleFactor)
        }
        
        let ctNode = ContentNode(id: contentObj.uuid, title: contentObj.name, feedId: contentObj.feedId, location: rawObjectGpsCCL)
        
        if fPath != "" && contentObj.type.lowercased() != "text" {
            
            if contentObj.type.lowercased() == "marker" {
                ctNode.addSphere(radius: 1, and: UIColor(hexColor: contentObj.hex_color))
            }
            if contentObj.type.lowercased() == "obj" {
                ctNode.addObj(fPath: fPath, contentObj: contentObj)
            }
            if contentObj.type.lowercased() == "usdz" {
                ctNode.addUSDZ(fPath: fPath, contentObj: contentObj)
            }
            if contentObj.type.lowercased() == "image" {
                ctNode.addImage(fPath: fPath, contentObj: contentObj, demo: localDemoContent)
            }
            if contentObj.type.lowercased() == "gif" {
                ctNode.addGif(fPath: fPath, contentObj: contentObj)
            }
            if contentObj.type.lowercased() == "audio" {
                ctNode.removeAllAudioPlayers()

                if (rlmSession.first?.showPlaceholders)! && !(rlmSession.first?.muteAudio)!{
                    ctNode.addSphere(radius: 0.05 + (nodeSize * 0.01), and: UIColor(hexColor: contentObj.hex_color))
                }
                addAudio(contentObj: contentObj, objectDistance: objectDistance, audioRangeRadius: audioRangeRadius, fPath: fPath, nodeSize: nodeSize)
            }
        } else {
            if contentObj.type.lowercased() == "text" {
                ctNode.addText(
                    contentObj: contentObj, objText: contentObj.text, extrusion: CGFloat(contentObj.scale * 0.1),
                    fontSize: CGFloat(contentObj.scale), color: UIColor(hexColor: contentObj.hex_color)
                )
            } else {
                if (rlmSession.first?.showPlaceholders)! {
                    ctNode.addSphere(radius: 10, and: UIColor.green)
                }
            }
        }
        
        if contentObj.billboard {
            let constraint = SCNBillboardConstraint()
            constraint.freeAxes = [.Y]
            ctNode.constraints = [constraint]
        }
        
        ctNode.scale  = SCNVector3(nodeSize, nodeSize, nodeSize)
        ctNode.tagComponents(nodeTag: contentObj.uuid)
        ctNode.name = contentObj.uuid
        ctNode.position = SCNVector3(contentPos.x, contentPos.y, contentPos.z)

        if contentObj.demo && !isInit {
            let ori = sceneView.pointOfView?.orientation
            let qRotation = SCNQuaternion(ori!.x, ori!.y, ori!.z, ori!.w)
            ctNode.rotate(by: qRotation, aroundTarget: (sceneView!.pointOfView?.position)!)
        }
        
        sceneView.scene.rootNode.addChildNode(ctNode)
    }
    
    
    func refreshScene() {
        print("RefreshScene")
        
        let curPos = CLLocation(latitude: (rlmSession.first?.currentLat)!, longitude: (rlmSession.first?.currentLng)!)
        let range = (rlmSession.first?.searchRadius)!
        
        let objsInRange          = objectsInRange(position: curPos, useManualRange: true, manualRange: range)
        let activeObjectsInRange = objsInRange.filter({$0.active && !$0.deleted})
        
        for n in mainScene.rootNode.childNodes {
            if n.isKind(of: ContentNode.self) { n.removeFromParentNode() }
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
                let objFeed = objFeeds.first
                
                if (objFeed?.active)! && inRange {
                    print("Obj in range: " + o.name)
                    if o.filePath != "" && o.type.lowercased() != "text" {
                        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
                        let fileName = (URL(string: o.filePath)?.lastPathComponent)!
                        let destinationUrl = documentsUrl.appendingPathComponent(fileName)
                        
                        print("UpdateScene: activeInRange: " + String(o.uuid))
                        
                        if (FileManager.default.fileExists(atPath: (destinationUrl?.path)! )) {
                            print("FileManager.default.fileExists")
                            addContentToScene(
                                contentObj: o, fPath: (destinationUrl?.path)!,
                                scaleFactor: (rlmSession.first?.scaleFactor)!,
                                localDemoContent: false
                            )
                        } else {
                            if o.type == "image" {
                                if UIImage(named: o.filePath) != nil {
                                    print("localDemoContent")
                                    addContentToScene(
                                        contentObj: o, fPath: o.filePath,
                                        scaleFactor: (rlmSession.first?.scaleFactor)!,
                                        localDemoContent: true
                                    )
                                }
                            }
                            print("MISSING DATA? " + String(o.filePath))
                        }
                    } else {
                        if (o.type.lowercased() == "text") {
                            addContentToScene(contentObj: o, fPath:"", scaleFactor: (rlmSession.first?.scaleFactor)!, localDemoContent: false )
                        }
                    }
                }
            }
        }
        
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: {_ in self.loadingView.isHidden = self.trackingState == 0 })
    }

    
    @objc func handleTap(rec: UITapGestureRecognizer) {
        print("handleTap")
        
        for n in mainScene.rootNode.childNodes {
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
                            
                            if (matchingObjs.first?.directLink)! && ((matchingObjs.first?.contentLink)! != "") {
                                self.openUrl(scheme: (matchingObjs.first?.contentLink)!)
                            } else {
                                if let a = sNodes.first as! ContentNode? {
                                    selectedNode = a
                                    showSeletedNodeActions(objData: matchingObjs.first!)
                                }
                            }
                        }
                    }
                }
            } else {
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
                        Double(gestureRecognizer.scale)
                    )
                }
            }
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
            message = "LOADING"
            trackingState = 0
            
        case .limited(.excessiveMotion):
            message = "LOCALIZING"
            trackingState = 0
            
        case .limited(.insufficientFeatures):
            message = "LOADING"
            trackingState = 1
            
        case .limited(.initializing):
            trackingState = 1
            message = "INITIALIZING"

        case .limited(.relocalizing):
            trackingState = 2
            message = "LOCALIZING"
        }

        loadingViewLabel.text = message
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: {_ in self.loadingView.isHidden  = self.trackingState == 0 })
    }
    
    
    func initScene() {
        print("initScene")

        qrCaptureSession.stopRunning()
        qrCapturePreviewLayer.removeFromSuperlayer()
        searchQRBtn.tintColor = self.view.window?.tintColor
        
        loadingViewLabel.text = "LOADING"
        loadingView.isHidden  = false
        
        mainScene = SCNScene(named: "art.scnassets/main.scn")!
        sceneView.scene = mainScene
        
        sceneView.session.delegate = self
        sceneView.delegate = self
        sceneView.audioListener = mainScene.rootNode
        
        configuration.isAutoFocusEnabled = true
        configuration.worldAlignment = .gravityAndHeading
        configuration.isLightEstimationEnabled = true

        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.cancelsTouchesInView = false
        optimizeCam()
        
        if (rlmSession.first?.autoUpdate)! {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: {_ in self.mainTimerUpdate() })
            Timer.scheduledTimer(withTimeInterval: 1 + ((rlmSession.first?.feedUpdateInterval)! * 0.25), repeats: false, block: { _ in self.isInit = true })
        }
        
    }
    
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        for item in metadataObjects {
            if let metadataObject = item as? AVMetadataMachineReadableCodeObject {
                
                if metadataObject.type == AVMetadataObject.ObjectType.qr {
                    qrUrl = metadataObject.stringValue!
                    
                    if (qrUrl != "") {
                        print(metadataObject.stringValue!)
                        showURLAlert(aMessage: metadataObject.stringValue!)
                    }
                    
                    qrCaptureSession.stopRunning()
                    qrCapturePreviewLayer.removeFromSuperlayer()
                }
                
                if metadataObject.type == AVMetadataObject.ObjectType.upce {
                    print(AVMetadataObject.ObjectType.upce)
                }
            }
        }
    }
    
    
    @objc func mainTimerUpdate() {
        print("mainUpdate: ARViewer")
        var needsRefresh = false
        
        for fo in feedObjects {
            if (fo.active && !fo.deleted) {
                if mainScene.rootNode.childNodes.filter( {$0.name == fo.uuid} ).count == 0 {
                    needsRefresh = true
                }
            }
        }
        
        if needsRefresh {
            print("mainUpdate: needsUpdate")
            refreshScene()
        }
        
        updateTimer.invalidate()
        
        if !updateTimer.isValid && (rlmSession.first?.autoUpdate)! {
            updateTimer = Timer.scheduledTimer(
                timeInterval: rlmSession.first!.feedUpdateInterval, target: self,
                selector: #selector(mainTimerUpdate), userInfo: nil, repeats: true)
        }
        
        Timer.scheduledTimer(
            withTimeInterval: 2, repeats: false, block: {_ in self.loadingView.isHidden  = self.trackingState == 0 }
        )
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        NavBarOps().showLogo(navCtrl: self.navigationController!, imageName: "Logo.png")

        loadingView.isHidden = false

        let pinchGR = UIPinchGestureRecognizer(
            target: self, action: #selector(ARViewer.handlePinch(_:))
        )
        
        pinchGR.delegate = self
        view.addGestureRecognizer(pinchGR)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear")
        isInit = false
        loadingView.isHidden = false
        initScene()
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: {_ in self.refreshScene() })
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear")
        progressBar.removeFromSuperview()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isInit = false

        loadingView.isHidden = false
        sceneView.session.pause()
        progressBar.removeFromSuperview()
    }
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print(error)
        print(error.localizedDescription)
        
        if error is ARError {
            initScene()
        }
    }
    
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("ArKit ViewerVC: sessionWasInterrupted")
    }
    
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("ArKit ViewerVC: sessionInterruptionEnded")
    }
    
    
}