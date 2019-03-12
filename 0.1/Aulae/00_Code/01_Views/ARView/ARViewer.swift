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
import Vision

class ARViewer: UIViewController, ARSCNViewDelegate, ARSessionDelegate, UIGestureRecognizerDelegate, AVCaptureMetadataOutputObjectsDelegate {
    
    var updateTimer = Timer()

    let realm = try! Realm()
    lazy var session: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var feeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
    
    var isTrackingQR = false
    var qrUrl = ""
    var qrCapturePreviewLayer = AVCaptureVideoPreviewLayer()
    var qrCaptureSession = AVCaptureSession()
        
    var trackingState = 3
    var contentZoom: Double = 1
    var audioListener: SCNNode? { return mainScene.rootNode }

    var configuration = AROrientationTrackingConfiguration()
    var mainScene = SCNScene()
    var selectedNode: ContentNode? = nil
    var selectedNodeY: Float = 0
    
    var currentPlanes: [SCNNode]? = nil
    let progressBar = UIProgressView()
    
    @IBOutlet var loadingViewLabel: UILabel!
    @IBOutlet var loadingView: UIView!
    @IBAction func refreshBtnAction(_ sender: UIBarButtonItem) {
        loadingView.isHidden = false
        
        NavBarOps().showProgressBar(navCtrl: self.navigationController!, progressBar: progressBar, view: self.view, timeoutPeriod: 2)
        
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
        
        NavBarOps().showProgressBar(navCtrl: self.navigationController!, progressBar: progressBar, view: self.view, timeoutPeriod: 2)
        
        if isTrackingQR {
            searchQRBtn.tintColor = self.view.window?.tintColor
            qrCaptureSession.stopRunning()
            qrCapturePreviewLayer.removeFromSuperlayer()
            isTrackingQR = false
        } else {
            captureQRCode()
            searchQRBtn.tintColor = UIColor.green
            isTrackingQR = true
        }
    }
    
    
    private func optimizeCam() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }
        // Enable HDR camera settings for the most realistic appearance with environmental lighting and physically based materials.
        camera.wantsHDR = true
        //camera.exposureOffset  = 0
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
            
            if (session.first?.muteAudio)! {
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

    
    func addContentToScene(contentObj: RLM_Obj, fPath: String, scaleFactor: Double) {
        print("AddContentToScene: " + String(contentObj.uuid))
        print("Adding: " + contentObj.type.lowercased() + ": " + fPath)
        
        let audioRangeRadius: Double = 1000
        let rawDeviceGpsCCL   = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!)
        let rawObjectGpsCCL   = CLLocation(latitude: contentObj.lat, longitude: contentObj.lng)
        let objectDistance    = rawDeviceGpsCCL.distance(from: rawObjectGpsCCL)
        
        var contentPos        = SCNVector3(contentObj.x_pos, contentObj.y_pos, contentObj.z_pos)
        if contentObj.world_position {
            contentPos = getNodeWorldPosition(baseOffset: 1.0, contentObj: contentObj, scaleFactor: scaleFactor)
        }
        
        var nodeSize: CGFloat = CGFloat(1 * contentObj.scale)
        if (session.first?.distanceScale)! && contentObj.world_scale {
            nodeSize = CGFloat( ( CGFloat(100 / (CGFloat(objectDistance) + 100) ) * CGFloat(objectDistance) ) / CGFloat(objectDistance) ) + CGFloat(0.1 / scaleFactor)
        }
        
        let ctNode = ContentNode(id: contentObj.uuid, title: contentObj.name, feedId: contentObj.feedId, location: rawObjectGpsCCL)
        
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
                ctNode.removeAllAudioPlayers()

                if (session.first?.showPlaceholders)! && !(session.first?.muteAudio)!{
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
            }
        }
        
        ctNode.scale  = SCNVector3(nodeSize, nodeSize, nodeSize)
        var yH: Float = 0.0
        
        if contentObj.style == 0 {
            yH = ctNode.boundingBox.max.y * 0.5
            let constraint = SCNBillboardConstraint()
            constraint.freeAxes = [.Y]
            ctNode.constraints = [constraint]
        }
        
        ctNode.position = SCNVector3(contentPos.x, (contentPos.y-yH), contentPos.z)
        ctNode.tagComponents(nodeTag: contentObj.uuid)
        ctNode.name = contentObj.uuid
        
        //rotateAnimation(node: ctNode, xAmt: 0, yAmt: 360, zAmt: 0, speed: contentObj.rotate)
        
//        if contentObj.rotate != 0 {
//            rotateAnimation(node: ctNode, xAmt: 0, yAmt: 360, zAmt: 0, speed: contentObj.rotate)
//        }
//
//        if contentObj.hoover != 0 {
//            addHooverAnimation(node: ctNode, distance: CGFloat(contentObj.hoover), speed: CGFloat(contentObj.hoover))
//        }
        
        sceneView.scene.rootNode.addChildNode(ctNode)
    }
    
    
    func refreshScene() {
        print("RefreshScene")
        
        let curPos = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!)
        let range = (session.first?.searchRadius)!
        
        // TODO: Get search range
        let objsInRange          = objectsInRange(position: curPos, useManualRange: true, manualRange: range)
        let activeObjectsInRange = objsInRange.filter({$0.active && !$0.deleted})
        
        for n in mainScene.rootNode.childNodes {
            if n.isKind(of: ContentNode.self) {
                n.removeFromParentNode()
            }
        }
        
        mainScene.rootNode.removeAllAudioPlayers()
        
        for o in activeObjectsInRange {
            let objFeeds = feeds.filter({$0.id == o.feedId})
            var inRange = true
            
            if o.radius != 0 {
                let d = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!).distance(from: CLLocation(latitude: o.lat, longitude: o.lng))
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
                            addContentToScene(contentObj: o, fPath: (destinationUrl?.path)!, scaleFactor: (session.first?.scaleFactor)! )
                        } else {
                            // TODO: Retry Download? + Increment Feed Error Count?
                            print("ERROR: FEED CONTENT: MISSING DATA: " + String(o.filePath))
                        }
                    } else {
                        if (o.type.lowercased() == "text") {
                            addContentToScene(contentObj: o, fPath:"", scaleFactor: (session.first?.scaleFactor)! )
                        }
                    }
                }
            }
        }
        
        loadingView.isHidden  = trackingState == 0

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
    
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        var message: String = ""
        trackingState = 2
        
        switch camera.trackingState {
        case .notAvailable:
            message = "Localizing..."
            trackingState = 2
            
        case .normal:
            message = "Lodaing..."
            trackingState = 0
            
        case .limited(.excessiveMotion):
            message = "Try slowing down your movement"
            trackingState = 0
            
        case .limited(.insufficientFeatures):
            message = "Try pointing at a flat surface or reloading the scene"
            trackingState = 1
            
        case .limited(.initializing):
            trackingState = 1
            message = "Initializing..."
            
        case .limited(.relocalizing):
            trackingState = 2
            message = "Localizing..."
        }

        loadingViewLabel.text = message
        loadingView.isHidden  = trackingState == 0
    }
    
    
    func initScene() {
        print("initScene")

        qrCaptureSession.stopRunning()
        qrCapturePreviewLayer.removeFromSuperlayer()
        searchQRBtn.tintColor = self.view.window?.tintColor
        
        loadingViewLabel.text = "Loading..."
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
        
        if (session.first?.autoUpdate)! {
            mainTimerUpdate()
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
        
        if !updateTimer.isValid && (session.first?.autoUpdate)! {
            updateTimer = Timer.scheduledTimer(
                timeInterval: session.first!.feedUpdateInterval, target: self,
                selector: #selector(mainTimerUpdate), userInfo: nil, repeats: true)
        }
        
        loadingView.isHidden  = trackingState == 0
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
        refreshScene()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear")
        progressBar.removeFromSuperview()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
