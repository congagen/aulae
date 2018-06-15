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
    lazy var feeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var objects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()

    var updateTimer = Timer()
    let updateInterval: Double = 10

    
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
    
    
    func feedsInRange(position: CLLocation, useManualRange: Bool, manualRange: Double) -> [RLM_Feed] {
        var feedList: [RLM_Feed] = []
        
        if ((feeds.count) > 0) {
            if (useManualRange) {
                feedList = (feeds.filter { (CLLocation(latitude: $0.lat, longitude: $0.lng).distance(from: position) < Double(manualRange))})
            } else {
                feedList = (feeds.filter { (CLLocation(latitude: $0.lat, longitude: $0.lng).distance(from: position) < Double($0.radius))})
            }
        }
        
        return feedList
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
    
    
    func listFeedObjects(feeds: [RLM_Feed]) -> [RLM_Obj] {
        
        return Array(objects)
    }
    
    
    func updateScene() {
        print("updateScene")

        let objScene = sceneView.scene
        objScene.removeAllParticleSystems()
        
        // Scenes in range
        let curPos = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!)
        let sInRange = feedsInRange(position: curPos, useManualRange: false, manualRange: 0)
        
        let objsInRange = listFeedObjects(feeds: sInRange)
        let objsInScene = sceneView.scene.rootNode.childNodes
        
        for o in objsInRange {
            if objsInScene.filter({$0.name == o.id}).count == 0 {
                let referenceURL = URL(fileURLWithPath: o.filePath)
                let objNode = SCNReferenceNode(url: referenceURL)
                objNode?.load()
                objNode?.name = o.id
                objScene.rootNode.addChildNode(objNode!)
            } else {
                // TODO: Check model version?
            }
        }
        
        for i in objsInScene {
            if objsInRange.filter({$0.name == i.name}).count == 0 {
                i.removeFromParentNode()
            }
        }
        
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
    
    
    @IBAction func refreshBtnAction(_ sender: UIBarButtonItem) {
        updateScene()
    }
    
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear: ViewerVC")
        updateScene()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mainUpdate()
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
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        plane.materials.first?.diffuse.contents = UIColor(red: 0, green: 1, blue: 1, alpha: 0.5)
        
        let planeNode = SCNNode(geometry: plane)
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        
        node.addChildNode(planeNode)
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
    }
    
}
