//
//  MapVC.swift
//  ArkitTest
//
//  Created by Tim Sandgren on 2018-05-22.
//  Copyright © 2018 Abstraqata. All rights reserved.
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
    lazy var rlmSession: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var rlmFeeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()

    var userSearchRadiusIndicator: MKCircle = MKCircle()

    let progressBar = UIProgressView()
    var selected: RLM_Obj? = nil
    var textField: UITextField? = nil
    
    @IBOutlet var reloadBtn: UIBarButtonItem!
    @IBAction func reloadBtnAction(_ sender: UIBarButtonItem) {
        print("reloadBtnAction")

        NavBarOps().showProgressBar(navCtrl: self.navigationController!, progressBar: progressBar, view: self.view, timeoutPeriod: 1)
        
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
        
        if d != nil {
            updateSearchRadiusDB(rDistance: d!)
    
        }

    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(circle: overlay as! MKCircle)
        circleRenderer.fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.05)
        circleRenderer.strokeColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5)
        circleRenderer.lineWidth = 1
        
        return circleRenderer
    }
    
    
    func updateMapSearchRadius() {
        print("updateMapSearchRadius")

        mapView.removeOverlay(userSearchRadiusIndicator)
        
        let cLoc = CLLocationCoordinate2D(
            latitude: mapView.userLocation.coordinate.latitude,
            longitude: mapView.userLocation.coordinate.longitude
        )
        
        if (rlmSession.first?.searchRadius)! >= 110000 {
            userSearchRadiusIndicator = MKCircle(center: cLoc, radius: Double( (rlmSession.first?.searchRadius)! - 100000 ))
        } else {
            userSearchRadiusIndicator = MKCircle(center: cLoc, radius: Double( (rlmSession.first?.searchRadius)! ))
        }
        
        mapView.addOverlay(userSearchRadiusIndicator)
    }
    
    
    func updateSearchRadiusDB(rDistance: Double) {
        print("updateSearchRadiusDB")
        print(rDistance)
        
        do {
            try realm.write {
                rlmSession.first?.searchRadius = rDistance
            }
        } catch {
            print("Error: \(error)")
        }
        
        updateMapSearchRadius()
    }
    
    
    func urlConfigurationTextField(textField: UITextField!)
    {
        if let _ = textField {
            self.textField = textField!
            textField.text! = (rlmSession.first?.defaultFeedUrl)!
        }
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
        
        if (rlmSession.first?.searchRadius)! >= 110000 {
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
        
        let uIv = (rlmSession.first?.mapUpdateInterval)! + 1
        
        if updateTimer.timeInterval != uIv || !((rlmSession.first?.autoUpdate)!) {
            updateTimer.invalidate()
        }
        
        if (rlmSession.first?.autoUpdate)! {
            if !updateTimer.isValid {
                updateTimer = Timer.scheduledTimer(
                    timeInterval: uIv,
                    target: self, selector: #selector(mainUpdate),
                    userInfo: nil, repeats: true)
            }
        }
        
        updateObjectAnnotations()
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

        if let o: MapAno = annotation as? MapAno {
            let fo = feedObjects.filter( {$0.uuid == o.id } )
            
            if fo.count > 0 {
                //pinView?.addSubview(pinIcon)
                
                if fo.first?.type == "image" {
                    pinView?.image = UIImage(named: "pin_image_ds")
                }
                
                if fo.first?.type == "usdz" {
                    pinView?.image = UIImage(named: "pin_model_ds")
                }
                
                if fo.first?.type == "gif" {
                    pinView?.image = UIImage(named: "pin_gif_ds")
                }
                
                if fo.first?.type == "audio" {
                    pinView?.image = UIImage(named: "pin_audio_ds")
                }
                
                if fo.first?.type == "text" {
                    pinView?.image = UIImage(named: "pin_text_ds")
                }
                
            }
        }
        
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
        mapView.showsPointsOfInterest = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsBuildings = true
        mapView.userLocation.title = ""
        mapView.tintColor = UIColor.black
        mapView.backgroundColor = UIColor.black
        
        mapView.mapType = .standard

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
        
        NavBarOps().showLogo(navCtrl: self.navigationController!, imageName: "Logo.png")
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear: MapVC" )
        
        for a in mapView.annotations {
            mapView.removeAnnotation(a)
        }
        
        updateObjectAnnotations()
        updateSearchRadiusDB(rDistance: (rlmSession.first?.searchRadius)!)
    }

}
