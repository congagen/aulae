//
//  MapVC.swift
//  ArkitTest
//
//  Created by Tim Sandgren on 2018-05-22.
//  Copyright © 2018 Tim Sandgren. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Foundation

import Realm
import RealmSwift

//class MapVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
class MapVC: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {

    var updateTimer = Timer()
    
    @IBOutlet var mapView: MKMapView!
    //let locationManager = CLLocationManager()

    lazy var realm = try! Realm()
    lazy var rlmSession:  Results<RLM_Session_117> = { self.realm.objects(RLM_Session_117.self) }()
    lazy var rlmSystem:   Results<RLM_SysSettings_117> = { self.realm.objects(RLM_SysSettings_117.self) }()

    lazy var rlmFeeds:    Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj>  = { self.realm.objects(RLM_Obj.self) }()

    var mapInit = 0
    
    var userSearchRadiusIndicator: MKCircle = MKCircle()

    let progressBar = UIProgressView()
    var selected: RLM_Obj? = nil
    var textField: UITextField? = nil
    
    @IBOutlet weak var resetBtn: UIBarButtonItem!
    @IBAction func resetBtnAction(_ sender: UIBarButtonItem) {
        updateSearchRadiusDB(rDistance: 99999999)
    }
    
    
    @IBOutlet var reloadBtn: UIBarButtonItem!
    @IBAction func reloadBtnAction(_ sender: UIBarButtonItem) {
        print("reloadBtnAction")

        UIOps().showProgressBar(navCtrl: self.navigationController!, progressBar: progressBar, view: self.view, timeoutPeriod: 3)
        
        initMapView()
        mainUpdate()
        updateObjectAnnotations()
    }
    
    
    @IBOutlet var navBar: UINavigationItem!
    
    func handleCancel(alertView: UIAlertAction!)
    {
        print(self.textField?.text! ?? "")
    }
    
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        print("handleLongPress")

        guard gestureRecognizer.state != .ended else { return }
        
        let mapTouchLocation = gestureRecognizer.location(in: mapView)
        
        let touchLocationCoordinate = mapView.convert(
            mapTouchLocation, toCoordinateFrom: mapView )
        
        let currentTouchLocation = CLLocation(
            latitude: touchLocationCoordinate.latitude,
            longitude: touchLocationCoordinate.longitude)
        
        let current = mapView!.userLocation.location
        let d = current?.distance(from: currentTouchLocation)
        
        // TODO: -> .changed?
        if gestureRecognizer.state == .began {
            print("Distance: " + String(d!))
            if d != nil { updateSearchRadiusDB(rDistance: d!) }
        }
    
    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(circle: overlay as! MKCircle)

        if (rlmSystem.first!.searchRadius > 99999988.0) {
            circleRenderer.strokeColor = UIColor.clear
            circleRenderer.strokeColor = UIColor.clear
            circleRenderer.lineWidth = 0
        } else {
            circleRenderer.fillColor   = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.00)
            circleRenderer.strokeColor = UIColor(red: 0.0, green: 1.0, blue: 0.3, alpha: 1.0)
            circleRenderer.lineWidth = 4
        }
        
        return circleRenderer
    }
    
    
    func updateMapSearchRadius() {
        //print("updateMapSearchRadius")

        mapView.removeOverlay(userSearchRadiusIndicator)
        
        let cLoc = CLLocationCoordinate2D(
            latitude: mapView.userLocation.coordinate.latitude,
            longitude: mapView.userLocation.coordinate.longitude
        )
        
        if (rlmSystem.first?.searchRadius)! >= 110000 {
            userSearchRadiusIndicator = MKCircle(center: cLoc, radius: Double( (rlmSystem.first?.searchRadius)! - 100000 ))
        } else {
            userSearchRadiusIndicator = MKCircle(center: cLoc, radius: Double( (rlmSystem.first?.searchRadius)! ))
        }
        
        mapView.addOverlay(userSearchRadiusIndicator)
    }
    
    
    func updateSearchRadiusDB(rDistance: Double) {
        print("updateSearchRadiusDB")
        //print(rDistance)
        
        do {
            try realm.write {
                rlmSystem.first?.searchRadius = rDistance
            }
        } catch {
            print("Error: \(error)")
        }
        
        updateMapSearchRadius()
    }
    
    
    func addRadiusOverlay(lat:Double, long:Double, radius:Double) {
        print("addRadiusOverlay")

        let currentOverlays = mapView.overlays.filter {
            $0.coordinate.latitude == lat && $0.coordinate.longitude == long
        }
        
        let locat: CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat, long)
        
        if currentOverlays.count == 0 {
            let areaCircle = MKCircle(center: locat, radius: Double(radius))
            mapView.addOverlay(areaCircle)
        }
    }
    
    
    func addAnoRadius(feObj: RLM_Obj) {
        print("addAnoRadius")

        let cLoc = CLLocationCoordinate2D( latitude: feObj.lat, longitude: feObj.lng )
        
        if (rlmSystem.first?.searchRadius)! >= 110000 {
            userSearchRadiusIndicator = MKCircle(center: cLoc, radius: Double( (feObj.radius) - 100000 ))
        } else {
            userSearchRadiusIndicator = MKCircle(center: cLoc, radius: Double( (feObj.radius) ))
        }
        
        mapView.addOverlay(userSearchRadiusIndicator)
        
    }

    
    func updateObjectAnnotations() {
        print("updateObjectAnnotations")
        
        let filterA:[MapAno] = mapView.annotations.filter( {$0.isKind(of: MapAno.self)} ) as! [MapAno]
            
        for a in filterA {
            // count > 0 or && (!feed.active || feed.deleted)
            
            if feedObjects.filter( {$0.uuid == a.id} ).count == 0 {
                mapView.removeAnnotation(a)
            }
        }
        
        for o in mapView.overlays {
            mapView.removeOverlay(o)
        }
        
        for fObj in feedObjects {
            if fObj.active && !fObj.deleted {
                let objFeeds = rlmFeeds.filter( {$0.id == fObj.feedId && !$0.deleted} )
                
                if objFeeds.count > 0 {
                    
                    if (objFeeds.first?.active)! && !(objFeeds.first?.deleted)! {
                        let ano = MapAno()
                        
                        ano.coordinate = CLLocationCoordinate2D(latitude: fObj.lat, longitude: fObj.lng)
                        ano.aType      = fObj.type
                        ano.id         = fObj.uuid
                        ano.name       = fObj.name
                        ano.title      = fObj.name
                        ano.subtitle   = (objFeeds.first?.name)!
                        
                        if fObj.radius > 0 {
                            addAnoRadius(feObj: fObj)
                        }
                        
                        if filterA.filter( {$0.id == fObj.uuid} ).count == 0 {
                            mapView.addAnnotation(ano)
                        }
                    }
                }
            }
        }
        
        updateMapSearchRadius()
        mapView.updateFocusIfNeeded()
    }
    
    
    @objc func mainUpdate() {
        print("mainUpdate")
        
        updateTimer.invalidate()
        
        if !updateTimer.isValid {
            updateTimer = Timer.scheduledTimer(
                timeInterval: (rlmSystem.first?.mapUpdateInterval)!,
                target:   self,
                selector: #selector(mainUpdate),
                userInfo: nil,
                repeats:  true
            )
        }
        
        if mapView.selectedAnnotations.count == 0 {
            updateObjectAnnotations()
        }
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if pinView == nil {
            pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        }
        else {
            pinView?.annotation = annotation
        }
        
        pinView?.image              = UIImage(named: "pin_ds")
        pinView?.canShowCallout     = true

//        if let o: MapAno = annotation as? MapAno {
//            let fo = feedObjects.filter( {$0.uuid == o.id } )
//            //print(fo.first?.hex_color ?? "")
//        }
        
        updateMapSearchRadius()
        return pinView
    }
    
    
    func getAnoObj(view: MKAnnotationView) -> RLM_Obj? {
        if let a: MapAno = view.annotation as? MapAno {
            let id      = a.id
            let results = feedObjects.filter({$0.uuid == id})
            
            if results.count > 0 {
                return results.first
            }
        }
        return nil
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("")
        
        if getAnoObj(view: view) != nil {
            selected = getAnoObj(view: view)!
            print(selected!)
        }
    }
    
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if getAnoObj(view: view) != nil {
            selected = getAnoObj(view: view)!
            print(selected!)
        }
    }

    
    
    func initMapView() {
        print("initMapView")
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsBuildings = true
        mapView.userLocation.title = ""
        mapView.tintColor = UIColor.black
        mapView.backgroundColor = UIColor.black
        
        mapView.mapType = .standard
    }
    
    
    func focusMap(focusLat: Double, focusLng: Double) {
        print("focusMap")
        
//        let center = CLLocationCoordinate2D(latitude: focusLat, longitude: focusLng)
//        let i_region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 135.68020269231502, longitudeDelta: 131.8359359933973))
        //mapView.setRegion(i_region, animated: false)
        
        mapView.setUserTrackingMode(MKUserTrackingMode.follow, animated: false)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        initMapView()
        mainUpdate()
        
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(MapVC.handleLongPress(_:)))
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        self.mapView.addGestureRecognizer(lpgr)
        
        //UIOps().showLogo(navCtrl: self.navigationController!, imageName: "Logo.png")
        focusMap(focusLat: rlmSession.first!.currentLat, focusLng: rlmSession.first!.currentLng)
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
//        if mapInit < 3 {
//            focusMap(focusLat: rlmSession.first!.currentLat, focusLng: rlmSession.first!.currentLng)
//            mapInit += 1
//        }
        
    }
    

    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear: MapVC" )
        
        for a in mapView.annotations {
            mapView.removeAnnotation(a)
        }
        
        updateObjectAnnotations()
        updateMapSearchRadius()
        updateSearchRadiusDB(rDistance: (rlmSystem.first?.searchRadius)!)
    }

}
