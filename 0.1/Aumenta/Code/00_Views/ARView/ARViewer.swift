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

class ARViewer: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    let realm = try! Realm()
    lazy var session: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var feeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
    
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
        activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook ]
        
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
        
        let rawDeviceGpsCCL  = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)! )
        let rawObjectGpsCCL  = CLLocation(latitude: contentObj.lat, longitude: contentObj.lng)
        let rawObjectAlt     = 0.0
        
        let objectDistance   = rawDeviceGpsCCL.distance(from: rawObjectGpsCCL)
        let distanceScale    = (objectDistance / scaleFactor) + 1000

        let translation      = MatrixHelper.transformMatrix(for: matrix_identity_float4x4, originLocation: rawDeviceGpsCCL, location: rawObjectGpsCCL)
        let translationSCNV  = SCNVector3.positionFromTransform(translation)
        
        var latLongXyz = SCNVector3(0, 0, 0)
        
        if (wordtrackError) {
            let objectXYZPos     = ValConverters().gps_to_ecef( latitude: contentObj.lat, longitude: contentObj.lng, altitude: 0.01 )
            let deviceXYZPos     = ValConverters().gps_to_ecef( latitude: rawDeviceGpsCCL.coordinate.latitude, longitude: rawDeviceGpsCCL.coordinate.longitude, altitude: 0.01 )
            let xPos = (((objectXYZPos[0] - objectXYZPos[0]) ) / distanceScale)
            let yPos = (((objectXYZPos[1] - objectXYZPos[1]) ) / distanceScale)

            latLongXyz       = SCNVector3(xPos, rawObjectAlt, yPos)
        } else {
            let normalisedTrans  = CGPoint(x: Double(translationSCNV.x) / distanceScale, y: Double(translationSCNV.z) / distanceScale )
            latLongXyz       = SCNVector3(normalisedTrans.x, CGFloat(rawObjectAlt), normalisedTrans.y)
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
                // TODO: Add placeholder if allowed in settings
            } else {
                // TODO: Add placeholder if allowed in settings
            }
        }
    }
    
    
    func updateScene() {
        print("Update Scene")
        
        let curPos = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!)
        
        // TODO:  Get search range
        let objsInRange   = objectsInRange(position: curPos, useManualRange: true, manualRange: 100000000000)
        let activeInRange = objsInRange.filter({$0.active && !$0.deleted})
        
        sceneView.pointOfView?.rotate(by: SCNQuaternion(x: 0, y: 0, z: 0, w: 0), aroundTarget: (sceneView.pointOfView?.position)!)
        
        for n in mainScene.rootNode.childNodes {
            //n.removeFromParentNode()
            
            if (n.name != "DefaultAmbientLight") {
                n.removeFromParentNode()
            }
        }
        
        mainScene.rootNode.enumerateChildNodes { (node, stop) in
            if (node.name != "DefaultAmbientLight") {
                node.removeFromParentNode()
                node.removeAllActions()
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
                    
                    addContentToScene(contentObj: o, fPath: (destinationUrl?.path)!, scaleFactor: 5 )
                    
                } else {
                    print("ERROR: FEED CONTENT: MISSING DATA: " + String(o.filePath))
                }
            } else {
                if (o.type == "text") {
                    addContentToScene(contentObj: o, fPath:"", scaleFactor: 5 )
                }
            }
        }
        
    }
    
    
    @objc func mainUpdate() {
        print("mainUpdate: ARViewer")
        
        if session.count > 0 {
            if updateTimer.timeInterval != updateInterval {
                updateTimer.invalidate()
            }
            
            updateInterval = session.first!.feedUpdateInterval
            
            if !updateTimer.isValid {
                updateTimer = Timer.scheduledTimer(
                    timeInterval: updateInterval,
                    target: self, selector: #selector(mainUpdate),
                    userInfo: nil, repeats: true)
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
                    addHooverAnimation(node: tappednode)
                } else {
                    tappednode.removeAllActions()
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
        
        configuration.worldAlignment = .gravityAndHeading
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.cancelsTouchesInView = false
        
        //sceneView.session.run(configuration)
    }
    
    
    override func viewDidLoad() {
        print("viewDidLoad")
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear")
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

