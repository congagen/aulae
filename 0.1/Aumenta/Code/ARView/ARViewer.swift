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
    
    let valConv = ValConverters()
    
    var deviceHeading: Float = 0
    var deviceHeadingNormal: Float = 0
    var deviceAngle:Double = 0
    var currentCamTransform: simd_float4x4 = simd_float4x4(float4(0), float4(0), float4(0), float4(0))
    var currentCamEuler: vector_float3 = vector_float3(x:0, y:0, z:0)
    
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
        
        let snapShot = sceneView.snapshot()
        //let jpg = UIImageJPEGRepresentation(snapShot, 1.0)
        
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
    
    
    func rotatePoint(target: CGPoint, aroundOrigin origin: CGPoint, byDegrees: CGFloat) -> CGPoint {
        let dx = target.x - origin.x
        let dy = target.y - origin.y
        let radius = sqrt(dx * dx + dy * dy)
        let azimuth = atan2(dy, dx)
        let newAzimuth = azimuth + byDegrees * CGFloat(.pi / 180.0)
        let x = origin.x + radius * cos(newAzimuth)
        let y = origin.y + radius * sin(newAzimuth)
        
        return CGPoint(x: x, y: y)
    }
    

    func rotateLatLong(lat: Double, lon: Double, angle: Double, center: CGPoint) -> CGPoint {
        
        let a = Double(center.x) + (cos(deg2rad(angle)))
        let b = Double(center.y) + (sin(deg2rad(angle)))
        
        let aa = Double(lat - Double(center.x)) - sin(deg2rad(angle))
        let bb = Double(lat - Double(center.x)) - cos(deg2rad(angle))
        
        let latR = a * aa * (lon - Double(center.y))
        let lonR = b * bb * (lon - Double(center.y))

        return CGPoint(x: latR, y: lonR)
    }
    
    func deg2rad(_ number: Double) -> Double {
        return number * Double.pi / 180.0
    }
    
    func rad2deg(radians: Double) -> Double {
        return radians * 180.0 / Double.pi
    }
    
    func cclBearing(point1 : CLLocation, point2 : CLLocation) -> Double {
        let x = point1.coordinate.longitude - point2.coordinate.longitude
        let y = point1.coordinate.latitude  - point2.coordinate.latitude
        
        return fmod(rad2deg(radians: atan2(y, x)), 360.0) + 90.0
    }
    
    
    func locationWithBearing(bearing:Double, distanceMeters:Double, origin:CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let distRadians = distanceMeters / (6372797.6)
        
        let lat1 = origin.latitude  * Double.pi / 180.0
        let lon1 = origin.longitude * Double.pi / 180.0
        
        let lat2 = asin(sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(bearing))
        let lon2 = lon1 + atan2(sin(bearing) * sin(distRadians) * cos(lat1), cos(distRadians) - sin(lat1) * sin(lat2))
        
        return CLLocationCoordinate2D(latitude: lat2 * 180 / Double.pi, longitude: lon2 * 180 / Double.pi)
    }
    
    
    static func translationMatrix_b(with matrix: matrix_float4x4, for translation : vector_float4) -> matrix_float4x4 {
        var matrix = matrix
        matrix.columns.3 = translation
        return matrix
    }
    
    static func rotateAroundY_b(with matrix: matrix_float4x4, for degrees: Float) -> matrix_float4x4 {
        var matrix : matrix_float4x4 = matrix
        
        matrix.columns.0.x = cos(degrees)
        matrix.columns.0.z = -sin(degrees)
        
        matrix.columns.2.x = sin(degrees)
        matrix.columns.2.z = cos(degrees)
        return matrix.inverse
    }
    
    static func transformMatrix(for matrix: simd_float4x4, originLocation: CLLocation, location: CLLocation) -> simd_float4x4 {
        let distance = Float(location.distance(from: originLocation))
        let bearing = originLocation.bearingToLocationRadian(location)
        let position = vector_float4(0.0, 0.0, -distance, 0.0)
        let translationMatrix = translationMatrix_b(with: matrix_identity_float4x4, for: position)
        let rotationMatrix = rotateAroundY_b(with: matrix_identity_float4x4, for: Float(bearing))
        let transformMatrix = simd_mul(rotationMatrix, translationMatrix)
        return simd_mul(matrix, transformMatrix)
    }
    
    
    func addContentToScene(contentObj: RLM_Obj, fPath: String) {
        print("addContentToScene: " + String(contentObj.id))
        
        let rawDeviceGps     = CGPoint(x: (session.first?.currentLat)!, y: (session.first?.currentLng)!)
        let rawObjectGps     = CGPoint(x: contentObj.lat, y: contentObj.lng)

        let rawDeviceGpsCCL  = CLLocation(latitude: CLLocationDegrees(rawDeviceGps.x), longitude: CLLocationDegrees(rawDeviceGps.y))
        let rawObjectGpsCCL  = CLLocation(latitude: CLLocationDegrees(rawObjectGps.x), longitude: CLLocationDegrees(rawObjectGps.y))
        
        let objectDistance   = rawDeviceGpsCCL.distance(from: rawObjectGpsCCL)
        let objectBearing    = cclBearing(point1: rawObjectGpsCCL, point2: rawDeviceGpsCCL)
        
        let offsetPos        = locationWithBearing(bearing: objectBearing, distanceMeters: objectDistance, origin: rawDeviceGpsCCL.coordinate )
        
        print("Distance:     " + String(objectDistance))
        print("Bearing:      " + String(objectBearing))
        print("RawObjectGps: " + String(rawObjectGps.x.description) + ", " + String(rawObjectGps.y.description))
        print("BearingGPS:   " + String(offsetPos.latitude) + ", " + String(offsetPos.longitude))
        
        let deviceXYZPos     = valConv.gps_to_ecef( latitude: Double(rawDeviceGps.x), longitude: Double(rawDeviceGps.y), altitude: 0.01 )
        let objectXYZPos     = valConv.gps_to_ecef( latitude: Double(rawObjectGps.x), longitude: Double(rawObjectGps.y), altitude: 0.01 )
        let compositeXY      = CGPoint(x: (objectXYZPos[0] - deviceXYZPos[0]) / 1000000.0, y: (objectXYZPos[1] - deviceXYZPos[1]) / 1000000.0 )
        
        
        let vPos = 0.0
        
        if fPath != "" {
            if contentObj.type.lowercased() == "obj" {
                print("ADDING OBJ TO SCENE: " + fPath)
                
                let node = objNode(fPath: fPath, contentObj: contentObj)
                node.position = SCNVector3(compositeXY.x, CGFloat(vPos), compositeXY.y)
                mainScene.rootNode.addChildNode(node)
            }
            
            if contentObj.type.lowercased() == "image" {
                print("ADDING IMAGE TO SCENE")
                
                let node = imageNode(fPath: fPath, contentObj: contentObj)
                node.position = SCNVector3(compositeXY.x, CGFloat(vPos), compositeXY.y)
                mainScene.rootNode.addChildNode(node)
            }
            
            if contentObj.type.lowercased() == "gif" {
                print("ADDING GIF TO SCENE")
                
                let node = ContentNode(title: "GifNode", location: rawObjectGpsCCL)
                node.addGif(fPath: fPath, contentObj: contentObj)

                let locationTransform = ARViewer.transformMatrix(for: matrix_identity_float4x4, originLocation: rawDeviceGpsCCL, location: rawObjectGpsCCL)
                let nodeAnchor = ARAnchor(transform: locationTransform)
                
                node.anchor = nodeAnchor

                //let node = gifNode(fPath: fPath, contentObj: contentObj)
                //node.position = SCNVector3(compositeXY.x, CGFloat(vPos), compositeXY.y)
                
                mainScene.rootNode.addChildNode(node)
            }
        } else {
            // TODO: Add placeholder if allowed in settings
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
            n.removeFromParentNode()
        }
        
        mainScene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
            node.removeAllActions()
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
        deviceHeading = currentCamEuler.y
        //deviceHeadingNormal = ((currentCamEuler.y + 0.00001) + .pi) / (2 * .pi)
        
        let h = valConv.cameraHeading(camera: cam!)
        deviceHeadingNormal = Float((Double(h + 0.00001) + Double.pi) / (2 * .pi))
        
        deviceAngle = 180.0 + (( Double(deviceHeading) / (2.0 * Double.pi) ) * 360.0)
        
        print("DeviceHeading:       " + String(deviceHeading))
        print("DeviceHeadingNormal: " + String(deviceHeadingNormal))
        print("DeviceAngle:         " + String(deviceAngle))
        
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
        sceneView.session.run(configuration)
    }
    
    
    override func viewDidLoad() {
        print("viewDidLoad")
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear")
        print(currentCamEuler)
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

