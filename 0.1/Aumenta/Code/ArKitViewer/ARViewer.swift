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
    
    var updateTimer = Timer()
    let updateInterval: Double = 10
    
    var mainScene = SCNScene()
    
    @IBOutlet var sceneView: ARSCNView!
    

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
    
    
    func addContentToScene(contentObj: RLM_Obj, fPath: String){
        print("Inserting Object: " + String(contentObj.id))

        //let devicePos = CLLocation(latitude: (session.first?.currentLat)!, longitude: (session.first?.currentLng)!)
        // SceneXYZ <- let objPos = CLLocation(latitude: contentObj.lat, longitude: contentObj.lng)

        if fPath != "" {
            if contentObj.type.lowercased() == "image" {
                //let img = UIImage(contentsOfFile: fPath)!

                let node = SCNNode(geometry: SCNSphere(radius: 100))
                node.geometry?.materials.first?.diffuse.contents = UIColor.green
                node.physicsBody? = .static()
                node.name = "TestNode"
//                node.geometry?.materials.first?.diffuse.contents = UIImage(named: "texture")

//                let distance = devicePos.distance(
//                    from: CLLocation( latitude: contentObj.lat, longitude: contentObj.lng )
//                )
//
//                let objScale: Double = contentObj.scale / distance

                mainScene.rootNode.addChildNode(node)

            }
        } else {
            print("contentObj.filePath == ?")
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        mainScene = SCNScene(named: "art.scnassets/main.scn")!
        sceneView.scene = mainScene
        
        let node = SCNNode(geometry: SCNSphere(radius: 1))
        node.geometry?.materials.first?.diffuse.contents = UIColor.green
        node.physicsBody? = .static()
        node.name = "TestNode"
        node.geometry?.materials.first?.diffuse.contents = UIImage(named: "Circle")
        node.position = SCNVector3(0.0, 0.0, -5.0)
        mainScene.rootNode.addChildNode(node)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
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

