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


class ViewerVC: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    let realm = try! Realm()
    lazy var session: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var sources: Results<RLM_Source> = { self.realm.objects(RLM_Source.self) }()

    
    func setUpSceneView() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    
    func loadObject(assetDir: String, format: String) {
        if let filePath = Bundle.main.path(forResource: "Test", ofType: format, inDirectory: assetDir) {
            let referenceURL = URL(fileURLWithPath: filePath)
            
            let referenceNode = SCNReferenceNode(url: referenceURL)
            referenceNode?.load()
            sceneView.scene.rootNode.addChildNode(referenceNode!)
        }
    }
    
    
    func sourcesInRange(position: CLLocation, useManualRange: Bool, manualRange: Double) -> [RLM_Source] {
        var sourceList: [RLM_Source] = []
        
        if ((sources.count) > 0) {
            if (useManualRange) {
                sourceList = (sources.filter { (CLLocation(latitude: $0.lat, longitude: $0.lng).distance(from: position) < Double(manualRange))})
            } else {
                sourceList = (sources.filter { (CLLocation(latitude: $0.lat, longitude: $0.lng).distance(from: position) < Double($0.radius))})
            }
        }
        
        return sourceList
    }
    
    
    func obejctsInRange(sObjects: [RLM_Obj], position: CLLocation, useManualRange: Bool, manualRange: Double) -> [RLM_Obj] {
        var objList: [RLM_Obj] = []

        if ((sObjects.count) > 0) {
            if (useManualRange) {
                objList = (sObjects.filter { (CLLocation(latitude: $0.lat, longitude: $0.lng).distance(from: position) < Double(manualRange))})
            } else {
                objList = (sObjects.filter { (CLLocation(latitude: $0.lat, longitude: $0.lng).distance(from: position) < Double($0.radius))})
            }
        }
        
        return objList
    }
    
    
    func listObjects(sources: [RLM_Source]) -> [RLM_Obj] {
        var objectList: [RLM_Obj] = []
        
        for s in sources {
            for o in s.sObjects {
                objectList.append(o)
            }
        }
        
        return objectList
    }
    
    
    func updateScene(sceneName: String) {
        let objScene = sceneView.scene
        objScene.removeAllParticleSystems()
        
        // Scenes in range
        let curPos = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!)
        let sInRange = sourcesInRange(position: curPos, useManualRange: false, manualRange: 0)
        let objList = listObjects(sources: sInRange)
        
        for o in objList {
            //let obj = SCNScene(named: "art.scnassets/" + o.fileName)
            let obj = SCNScene(named: "art.scnassets/test.dae")
            
            objScene.rootNode.addChildNode((obj?.rootNode.childNode(withName: "test.dae", recursively: true)!)!)
        }
        
    }
    
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear: ViewerVC")
        updateScene(sceneName: "main.scn")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpSceneView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print(error)
    }
    
}


extension ViewerVC {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // 2
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        // 3
        plane.materials.first?.diffuse.contents = UIColor(red: 0, green: 1, blue: 1, alpha: 0.5)
        
        // 4
        let planeNode = SCNNode(geometry: plane)
        
        // 5
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        
        // 6
        node.addChildNode(planeNode)
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        // 2
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height
        
        // 3
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
    }
    
}
