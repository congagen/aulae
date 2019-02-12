//
//  ARViewer_.swift
//  Aumenta
//
//  Created by Tim Sandgren on 2019-02-11.
//  Copyright © 2019 Abstraqata. All rights reserved.
//
//

import UIKit
import SceneKit
import Foundation
import MapKit
import ARKit

import Realm
import RealmSwift


class ARViewer: UIViewController, ARSCNViewDelegate {
    
    
    let realm = try! Realm()
    lazy var session: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var feeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
    
    var currentCamTransform: simd_float4x4 = simd_float4x4(float4(0), float4(0), float4(0), float4(0))
    
    var camFrame: ARFrame? = nil
    var cam: ARCamera? = nil
    
    var updateTimer = Timer()
    let updateInterval: Double = 10
    
    var mainScene = SCNScene()
    
    
    @IBAction func refreshBtnAction(_ sender: UIBarButtonItem) {
        updateScene()
    }
    
    
    @IBAction func sharePhotoBtn(_ sender: UIBarButtonItem) {
        let capImg: UIImage = UIImage(cgImage: sceneView.snapshot().cgImage!)
        
        let imageToShare = [capImg]
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true)
    }
    
    
    @IBOutlet var sceneView: ARSCNView!
    
    
    func addDebugObj(objSize: Double)  {
        let node = SCNNode(geometry: SCNSphere(radius: CGFloat(objSize) ))
        node.geometry?.materials.first?.diffuse.contents = UIColor.green
        node.physicsBody? = .static()
        node.name = "TestNode"
        //node.geometry?.materials.first?.diffuse.contents = UIImage(named: "star")
        
        let objScene = SCNScene(named: "art.scnassets/bunny.dae")
        objScene!.rootNode.position = SCNVector3(5.0, 0.0, -25.0)
        mainScene.rootNode.addChildNode(objScene!.rootNode)
        
        node.position = SCNVector3(5.0, 0.0, -5.0)
        mainScene.rootNode.addChildNode(node)
    }
    

    func loadCollada(path: String) -> SCNNode {

        let urlPath = URL(fileURLWithPath: path)
        let fileName = urlPath.lastPathComponent
        let fileDir = urlPath.deletingLastPathComponent().path

        print("Attempting to load model: " + String(fileDir) + " Filename: " + String(fileName))

        do {
            let scene = try SCNScene(url: urlPath, options: nil)
            return scene.rootNode.childNodes[0] as SCNNode
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
        // Latitudes range from 0 to 90. Longitudes range from 0 to 180.
        // [+] if obj.lat/long < user.lat/long else [-] ?
        print("Inserting Object: " + String(contentObj.id))

         let devicePos = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!)
        // SceneXYZ <- let objPos = CLLocation(latitude: contentObj.lat, longitude: contentObj.lng)

//        let valConv = ValConverters()
//        let arPos = valConv.gps_to_ecef(latitude: contentObj.lat, longitude: contentObj.lng, altitude: 0)

//        let xPos = arPos[0] / 1000000
//        let zPos = arPos[2] / 1000000
        
//        let distance = devicePos.distance(
//            from: CLLocation( latitude: contentObj.lat, longitude: contentObj.lng )
//        )
//        let objScale: Double = contentObj.scale / distance
        
        if fPath != "" {
            
            if contentObj.type.lowercased() == "image" {
                print("IMAGE")
                
                let img = UIImage(contentsOfFile: fPath)!
                let node = SCNNode(geometry: SCNPlane(width: 1, height: 1))
                
                node.physicsBody? = .static()
                node.name = contentObj.name
                node.geometry?.materials.first?.diffuse.contents = UIColor.white
                node.geometry?.materials.first?.diffuse.contents = img
                node.position = SCNVector3(0.0, 0.0, -3.0)

                mainScene.rootNode.addChildNode(node)
            }
            
            if contentObj.type.lowercased() == "dae" {
                let objScene = SCNScene(named: fPath)
                mainScene.rootNode.addChildNode(objScene!.rootNode)
            }
            
        } else {
            let text = SCNText(string: contentObj.text+"!", extrusionDepth: 0.1)
            text.alignmentMode = kCAAlignmentCenter
            
            let node = SCNNode(geometry: text)
            node.physicsBody? = .static()
            node.name = contentObj.name
            node.position = SCNVector3(0.0, 0.0, -5.0)
            
            mainScene.rootNode.addChildNode(node)
        }
    }
    
    
    func updateScene() {
        print("updateScene")
        
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
                    // TODO: Add Icon/Placeholder
                    print("File missing: " + String(o.filePath))
                }
            } else {
                // Add text w o.style
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
            
            if !updateTimer.isValid {
                updateTimer = Timer.scheduledTimer(
                    timeInterval: updateInterval,
                    target: self, selector: #selector(mainUpdate),
                    userInfo: nil, repeats: true)
            }
        }
    }
    
    
    func initScene() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        mainScene = SCNScene(named: "art.scnassets/main.scn")!
        sceneView.scene = mainScene
        
        updateScene()
    }
    
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Do something with the new transform
        
        if (!(camFrame != nil)) {
            camFrame = frame
        }
    
        if (!(cam != nil)) {
            cam = frame.camera
        }
        
        currentCamTransform = frame.camera.transform
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initScene()
        mainUpdate()
        
        addDebugObj(objSize: 0.5)
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
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

