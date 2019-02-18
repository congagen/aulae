//
//  ARViewer_.swift
//  Aumenta
//
//  Created by Tim Sandgren on 2019-02-11.
//  Copyright © 2019 Abstraqata. All rights reserved.


import UIKit
import SceneKit
import Foundation
import MapKit
import ARKit

import Realm
import RealmSwift



class ARViewer: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    let realm = try! Realm()
    lazy var session: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var feeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
    
    var currentCamTransform: simd_float4x4 = simd_float4x4(float4(0), float4(0), float4(0), float4(0))
    var currentCamEuler: vector_float3 = vector_float3(x:0, y:0, z:0)

    let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(rec:)))

    var camFrame: ARFrame? = nil
    var cam: ARCamera? = nil
    
    var updateTimer = Timer()
    var updateInterval: Double = 10
    
    var mainScene = SCNScene()
    
    
    @IBAction func refreshBtnAction(_ sender: UIBarButtonItem) {
        updateScene()
    }
    
    @IBOutlet var sceneView: ARSCNView!
    
    
    @IBAction func sharePhotoBtn(_ sender: UIBarButtonItem) {
        // let capImg = UIImage(cgImage: sceneView.snapshot().cgImage!)
        
        let snapShot = try sceneView.snapshot()
        //let jpg = UIImageJPEGRepresentation(snapShot, 1.0)
        
        let imageToShare = [snapShot]
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook ]
        
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
        
    }
    
    
    func sharePhoto(){
        let renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: [:])
        renderer.scene = sceneView.scene
        renderer.pointOfView = sceneView.pointOfView
        let snapShot = renderer.snapshot(atTime: TimeInterval(0), with: CGSize(width: 100, height: 100), antialiasingMode: .none)
        
        let imageToShare = [snapShot]
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook ]

        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    
    func addDebugObj(objSize: Double)  {
        let node = SCNNode(geometry: SCNSphere(radius: CGFloat(objSize) ))
        node.geometry?.materials.first?.diffuse.contents = UIColor.green
        node.physicsBody? = .static()
        node.name = "TestNode"
        //node.geometry?.materials.first?.diffuse.contents = UIImage(named: "star")
        node.position = SCNVector3(5.0, 0.0, -5.0)
        mainScene.rootNode.addChildNode(node)
        
        let objScene = SCNScene(named: "art.scnassets/bunny.dae")
        objScene!.rootNode.position = SCNVector3(0.0, 0.0, -25.0)
        mainScene.rootNode.addChildNode(objScene!.rootNode)
    }
    
    
    
    @objc func handleTap(rec: UITapGestureRecognizer){
        
        if rec.state == .ended {
            let location: CGPoint = rec.location(in: sceneView)
            let hits = self.sceneView.hitTest(location, options: nil)
            if !hits.isEmpty{
                let tappedNode = hits.first?.node
                print(tappedNode?.name!)
            }
        }
    }
    
    
    func loadCollada(path: String) -> SCNNode {

        let urlPath = URL(fileURLWithPath: path)
        let fileName = urlPath.lastPathComponent
        let fileDir = urlPath.deletingLastPathComponent().path

        print("Attempting to load model: " + String(fileDir) + " Filename: " + String(fileName))

        do {
            let scene = try SCNScene(url: urlPath, options: nil)
            return scene.rootNode
        } catch {
            print(error)
        }

        return SCNNode()
    }


    func obejctsInRange(position: CLLocation, useManualRange: Bool, manualRange: Double) -> [RLM_Obj] {
        var objList: [RLM_Obj] = []

        if (useManualRange) {
            objList = feedObjects.filter({ (CLLocation(latitude: $0.lat, longitude: $0.lng).distance(from: position) <= Double(manualRange)) })
        } else {
            objList = feedObjects.filter({ (CLLocation(latitude: $0.lat, longitude: $0.lng).distance(from: position) <= Double($0.radius))   })
        }

        return objList
    }
    
    
    
    func addContentToScene(contentObj: RLM_Obj, fPath: String) {
        print("addContentToScene: " + String(contentObj.id))
        
        print(currentCamTransform)
        print(currentCamEuler)

        let devicePos = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!)
        let valConv = ValConverters()

        let objXYZPos = valConv.gps_to_ecef(
            latitude:  contentObj.lat,
            longitude: contentObj.lng,
            altitude: 0.01
        )
        
        let deviceXYZPos = valConv.gps_to_ecef(
            latitude:  devicePos.coordinate.latitude,
            longitude: devicePos.coordinate.longitude,
            altitude: 0.01
        )

        let xPos = (objXYZPos[0] - deviceXYZPos[0]) / 1000000.0
        let yPos = (objXYZPos[1] - deviceXYZPos[1]) / 1000000.0
        let vPos = 0.0


        if fPath != "" {
            if contentObj.type.lowercased() == "image" {
                print("ADDING IMAGE TO SCENE")
                
                let node = imageNode(fPath: fPath, contentObj: contentObj)
                node.position = SCNVector3(xPos, vPos, yPos)
                
                mainScene.rootNode.addChildNode(node)
            }
            
            if contentObj.type.lowercased() == "dae" {
                print("ADDING DAEOBJ TO SCENE: " + fPath)
            
                let node = daeNode(fPath: fPath, contentObj: contentObj)
                node.position = SCNVector3(xPos, vPos, yPos)
                
                mainScene.rootNode.addChildNode(node)
            }
            
            if contentObj.type.lowercased() == "gif" {
                print("ADDING GIF TO SCENE")
            
                let node = gifNode(fPath: fPath, contentObj: contentObj)
                node.position = SCNVector3(xPos, vPos, yPos)
                mainScene.rootNode.addChildNode(node)
            }
        }
    }
    
    
    func updateScene() {
        print("Update Scene")
        
        // Scenes in range
        let curPos = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!)
        
        // TODO:  Get search range
        let objsInRange = obejctsInRange(position: curPos, useManualRange: true, manualRange: 100000000000)
        
        mainScene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
        
        for o in objsInRange {
            print("Obj in range: ")
            
            if o.filePath != "" && !(o.type == "text") {
                let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
                let fileName = (URL(string: o.filePath)?.lastPathComponent)!
                let destinationUrl = documentsUrl.appendingPathComponent(fileName)
                
                print("UpdateScene: objsInRange: " + String(o.id))
                
                if (FileManager.default.fileExists(atPath: (destinationUrl?.path)! )) {
                    print("FileManager.default.fileExists")
                    
                    print("objsInScene.filter({$0.name == String(o.id)}).count == 0")
                    addContentToScene(contentObj: o, fPath: (destinationUrl?.path)! )

                } else {
                    print("ERROR: FEED CONTENT: MISSING DATA: " + String(o.filePath))
                }
            } else {
                if (o.type == "text") {
                    addContentToScene(contentObj: o, fPath:"" )
                }
            }
        }
    }
    
    
    @objc func mainUpdate() {
        print("mainUpdate: ARViewer")
        
        // updateScene()
        
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
    
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        camFrame = frame
        cam = camFrame!.camera

        currentCamTransform = cam!.transform
        currentCamEuler = cam!.eulerAngles
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        print("renderer")
    }
    
    
    func initScene() {
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.showsStatistics = true
        
        mainScene = SCNScene(named: "art.scnassets/main.scn")!
        sceneView.scene = mainScene
        
        sceneView.allowsCameraControl = true
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
    }
    
    
    override func viewDidLoad() {
        initScene()
        updateScene()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let configuration = AROrientationTrackingConfiguration()
        sceneView.session.run(configuration)
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

