//
//  ViewController.swift
//  ArkitTest
//
//  Created by Tim Sandgren on 2018-05-19.
//  Copyright © 2018 Abstraqata. All rights reserved.
//

import UIKit
import SceneKit
import Foundation
import MapKit
import ARKit

import Realm
import RealmSwift


class ViewerVC: UIViewController, ARSCNViewDelegate, MKMapViewDelegate, SceneLocationViewDelegate {
    
    
    func sceneLocationViewDidAddSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        print("add scene location estimate, position: \(position), location: \(location.coordinate), accuracy: \(location.horizontalAccuracy), date: \(location.timestamp)")
    }
    
    func sceneLocationViewDidRemoveSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        print("remove scene location estimate, position: \(position), location: \(location.coordinate), accuracy: \(location.horizontalAccuracy), date: \(location.timestamp)")
    }
    
    func sceneLocationViewDidConfirmLocationOfNode(sceneLocationView: SceneLocationView, node: LocationNode) {
    }
    
    func sceneLocationViewDidSetupSceneNode(sceneLocationView: SceneLocationView, sceneNode: SCNNode) {
        
    }
    
    func sceneLocationViewDidUpdateLocationAndScaleOfLocationNode(sceneLocationView: SceneLocationView, locationNode: LocationNode) {
        
    }
    

    var sceneLocationView = SceneLocationView()
    
    let realm = try! Realm()
    lazy var session: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var feeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
    
    var updateTimer = Timer()
    let updateInterval: Double = 10

    
    @IBAction func refreshBtnAction(_ sender: UIBarButtonItem) {
        print("refresh button")
        updateScene()
    }
    

    func loadObject(sceneView: ARSCNView, assetDir: String, format: String) {
        if let filePath = Bundle.main.path(forResource: "Test", ofType: format, inDirectory: assetDir) {
            let referenceURL = URL(fileURLWithPath: filePath)
            
            let referenceNode = SCNReferenceNode(url: referenceURL)
            referenceNode?.load()
            sceneView.scene.rootNode.addChildNode(referenceNode!)
        }
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
    
    
    func addContentToScene(contentObj: RLM_Obj, fPath: String){
        print("Inserting Object: " + String(contentObj.id))
        
        let devicePos = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!)
        let objPos = CLLocation(latitude: contentObj.lat, longitude: contentObj.lng)
        
        
        if fPath != "" {
            if contentObj.type.lowercased() == "image" {
                print("IMAGE")
                
                let img = UIImage(contentsOfFile: fPath)!
                
                let distance = devicePos.distance(from: CLLocation(latitude: contentObj.lat, longitude: contentObj.lng))
                let objScale: Double = contentObj.scale / distance
                
                //TODO: let xPos = devicePos.coordinate.latitude
                //TODO: let yPos = devicePos.coordinate.longitude
                //TODO: let zPos = devicePos.altitude
                
                let annotationNode = LocationAnnotationNode(location: objPos, image: img)
                // annotationNode.scale = SCNVector3(x: Float(objScale), y: Float(objScale), z: Float(objScale))
                // annotationNode.scale = SCNVector3(x: Float(10000), y: Float(10000), z: Float(10000))
                annotationNode.name = contentObj.id
                
                sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
            }
        } else {
            print("contentObj.filePath == ?")
        }
    }
    
    
    func updateScene() {
        print("updateScene")
        
        // Scenes in range
        let curPos = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!)
        
        // TODO:
        // let objsInRange = obejctsInRange(position: curPos, useManualRange: false, manualRange: 1)
        let objsInRange = obejctsInRange(position: curPos, useManualRange: true, manualRange: 100000000000)
        let locationNodesInScene = sceneLocationView.locationNodes
        
        for o in objsInRange {
            
//            let presentInScene = sceneLocationView.locationNodes.filter({ $0.name == o.id} )
//            if presentInScene.count > 0 {
//                for os in presentInScene {
//
//                    sceneLocationView.removeLocationNode(locationNode: os)
//                }
//            }
            
            if o.filePath != "" && !(o.type == "text") {
                let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
                let fileName = (URL(string: o.filePath)?.lastPathComponent)!
                let destinationUrl = documentsUrl.appendingPathComponent(fileName)
                
                print("UpdateScene: objsInRange: " + String(o.id))
                
                // TODO: Check if present in scene else insert:
                if (FileManager.default.fileExists(atPath: (destinationUrl?.path)! )) {
                    print("FileManager.default.fileExists")
                    
                    if locationNodesInScene.filter({$0.name == String(o.id)}).count == 0 {
                        print("objsInScene.filter({$0.name == String(o.id)}).count == 0")
                        addContentToScene(contentObj: o, fPath: (destinationUrl?.path)! )
                    }
                } else {
                    print("File missing: " + String(o.filePath))
                }
            } else {
                // Add text w o.style
            }
        }
        
//        for i in locationNodesInScene {
//            if objsInRange.filter({$0.name == i.name}).count == 0 {
//                i.removeFromParentNode()
//            }
//        }
        
    }
    
    
    @objc func mainUpdate() {
        print("mainUpdate: ViewerVC")
        
        updateScene()
        
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
    
    
//    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
//        // Place content only for anchors found by plane detection.
//        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
//
//        // Create a SceneKit plane to visualize the plane anchor using its position and extent.
//        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
//        let planeNode = SCNNode(geometry: plane)
//        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
//
//        // `SCNPlane` is vertically oriented in its local coordinate space, so
//        // rotate the plane to match the horizontal orientation of `ARPlaneAnchor`.
//        planeNode.eulerAngles.x = -.pi / 2
//
//        // Make the plane visualization semitransparent to clearly show real-world placement.
//        planeNode.opacity = 0.25
//
//
//        // Add the plane visualization to the ARKit-managed node so that it tracks
//        // changes in the plane anchor as plane estimation continues.
//        node.addChildNode(planeNode)
//    }
    
//    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        // Update content only for plane anchors and nodes matching the setup created in `renderer(_:didAdd:for:)`.
//        guard let planeAnchor = anchor as?  ARPlaneAnchor,
//            let planeNode = node.childNodes.first,
//            let plane = planeNode.geometry as? SCNPlane
//            else { return }
//
//        // Plane estimation may shift the center of a plane relative to its anchor's transform.
//        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
//
//        // Plane estimation may also extend planes, or remove one plane to merge its extent into another.
//        plane.width = CGFloat(planeAnchor.extent.x)
//        plane.height = CGFloat(planeAnchor.extent.z)
//    }
    
    
// -------------------------------------------------------------------------------------------------------------

    
    func initScene() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneLocationView.session.run(configuration)
        sceneLocationView.run()
        
        sceneLocationView.showsStatistics = true
        sceneLocationView.showAxesNode = true
        sceneLocationView.showFeaturePoints = true
        sceneLocationView.locationDelegate = self
        
        sceneLocationView.delegate = self
        sceneLocationView.showsStatistics = true
        sceneLocationView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]

        view.addSubview(sceneLocationView)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear: ViewerVC")
        updateScene()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initScene()
        mainUpdate()
    }
    
    
// -------------------------------------------------------------------------------------------------------------

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initScene()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneLocationView.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sceneLocationView.frame = view.bounds
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
