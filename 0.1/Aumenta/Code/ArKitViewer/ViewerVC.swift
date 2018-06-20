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
    
//    var mainScene: SCNScene? = nil
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
    
    
    
    func loadObject(assetDir: String, format: String) {
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
    
    
    func listFeedObjects(feeds: [RLM_Feed]) -> [RLM_Obj] {
        
        return Array(feedObjects)
    }
    
    
    func updateScene() {
        print("updateScene")
        
        // Scenes in range
        let curPos = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!)
        
        // TODO:
        // let objsInRange = obejctsInRange(position: curPos, useManualRange: false, manualRange: 1)
        let objsInRange = obejctsInRange(position: curPos, useManualRange: true, manualRange: 0) // <- REMOVE
        let objsInScene = sceneView.scene.rootNode.childNodes
        
        for o in objsInRange {
            print("UpdateScene:objsInRange: " + String(o.id))
            
            if !(FileManager.default.fileExists(atPath: o.filePath )) && o.type != "text" {
                if objsInScene.filter({$0.name == String(o.id)}).count == 0 {
                    print("Inserting Object: " + String(o.id))
                    
                    let referenceURL = URL(fileURLWithPath: o.filePath)
                    let objNode = SCNReferenceNode(url: referenceURL)
                    objNode?.load()
                    //objNode?.name = o.id
                    //sceneView.scene.rootNode.addChildNode(objNode!)
                    
                    let coordinate = CLLocationCoordinate2D(latitude: o.lat, longitude: o.lng)
                    let location = CLLocation(coordinate: coordinate, altitude: 300)
                    let image = UIImage(named: "star")!
                    
                    let annotationNode = LocationAnnotationNode(location: location, image: image)
                    
                    sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
                    
                    //mainScene?.rootNode.addChildNode(objNode!)
                } else {
                    // TODO: Check model version?
                }
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
    
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Place content only for anchors found by plane detection.
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Create a SceneKit plane to visualize the plane anchor using its position and extent.
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: plane)
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        // `SCNPlane` is vertically oriented in its local coordinate space, so
        // rotate the plane to match the horizontal orientation of `ARPlaneAnchor`.
        planeNode.eulerAngles.x = -.pi / 2
        
        // Make the plane visualization semitransparent to clearly show real-world placement.
        planeNode.opacity = 0.25
        
        // Add the plane visualization to the ARKit-managed node so that it tracks
        // changes in the plane anchor as plane estimation continues.
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Update content only for plane anchors and nodes matching the setup created in `renderer(_:didAdd:for:)`.
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        // Plane estimation may shift the center of a plane relative to its anchor's transform.
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        // Plane estimation may also extend planes, or remove one plane to merge its extent into another.
        plane.width = CGFloat(planeAnchor.extent.x)
        plane.height = CGFloat(planeAnchor.extent.z)
    }
    
    
// -------------------------------------------------------------------------------------------------------------

    
    func setUpSceneView() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    
    func initScene(){
        sceneLocationView.run()
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
        setUpSceneView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
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
