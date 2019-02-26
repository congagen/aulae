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


class MapVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {

    var updateTimer = Timer()
    
    @IBOutlet var mapView: MKMapView!
    let locationManager = CLLocationManager()

    lazy var realm = try! Realm()
    lazy var session: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var feeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()

    var curLat = 0.0
    var curLng = 0.0
    var curAlt = 0.0

    
    var textField: UITextField? = nil
    
    @IBOutlet var searchBtn: UIBarButtonItem!
    @IBAction func searchBtnAction(_ sender: UIBarButtonItem) {
        
    }
    
    @IBOutlet var reloadBtn: UIBarButtonItem!
    @IBAction func reloadBtnAction(_ sender: UIBarButtonItem) {
        initMapView()
        mainUpdate()
    }
    
    
    @IBOutlet var navBar: UINavigationItem!
    

    func handleCancel(alertView: UIAlertAction!)
    {
        print(self.textField?.text! ?? "")
    }
    
    
    func updateSearchRadius(rDistance: Double) {
       
        do {
            try realm.write {
               session.first?.searchRadius = rDistance
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state != .ended else { return }
        
        let mapTouchLocation = gestureRecognizer.location(in: mapView)
        
        let touchLocationCoordinate = mapView.convert(
            mapTouchLocation, toCoordinateFrom: mapView )
        
        let currentTouchLocation = CLLocation(
            latitude: touchLocationCoordinate.latitude,
            longitude: touchLocationCoordinate.longitude)
        
        let current = mapView!.userLocation.location
        let d = current?.distance(from: currentTouchLocation)
        
        updateSearchRadius(rDistance: d!)
        updateviewRadius()

    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(circle: overlay as! MKCircle)
        circleRenderer.fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.05)
        circleRenderer.strokeColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5)
        circleRenderer.lineWidth = 1
        
        return circleRenderer
    }
    
    func updateviewRadius() {
        
        for o in mapView.overlays {
            mapView.removeOverlay(o)
        }
        
        let cLoc = CLLocationCoordinate2D(
            latitude: mapView.userLocation.coordinate.latitude,
            longitude: mapView.userLocation.coordinate.longitude
        )
        
        let areaCircle = MKCircle(
            center: cLoc, radius: Double((session.first?.searchRadius)!)
        )
        
        mapView.addOverlay(areaCircle)
        
    }
    
    
    
    func urlConfigurationTextField(textField: UITextField!)
    {
        if let _ = textField {
            self.textField = textField!
            textField.text! = (session.first?.debugUrl)!
        }
    }
    
    
    
    func addRadiusOverlay(lat:Double, long:Double, radius:Double) {
        
        let currentOverlays = mapView.overlays.filter {
            $0.coordinate.latitude == lat && $0.coordinate.longitude == long
        }
        
        let locat: CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat, long)
        
        if currentOverlays.count == 0 {
            let areaCircle = MKCircle(center: locat, radius: Double(radius))
            mapView.addOverlay(areaCircle)
        }
    }
    
    
    func reloadAnnotations(){
        let filterA = mapView.annotations.filter( {$0.isKind(of: MapAno.self)} )

        for a in filterA {
            mapView.removeAnnotation(a)
        }
        
        updateObjectAnnotations()
    }
    
    
    func updateObjectAnnotations() {
        print("updateObjectAnnotations")
        
        for fo in feedObjects {
            if fo.active && !fo.deleted {
                // Omitt location marker
                // a.isKind(of: MKUserLocation)
                let filterA = mapView.annotations.filter( {$0.isKind(of: MapAno.self)} )
                let fOnMap = filterA.filter( {$0.coordinate.latitude == fo.lat && $0.coordinate.longitude == fo.lng} )
                
                let objFeed = feeds.filter( {$0.id == fo.feedId && $0.deleted == false} )
                
                print("FeedObject: " + String(fo.lat) + ", " + String(fo.lng))
                
                if fOnMap.count == 0 {
                    print("Adding annotation: " + String(fo.id) )
                    let ano = MapAno()
                    ano.coordinate = CLLocationCoordinate2D(latitude: fo.lat, longitude: fo.lng)
                    
                    ano.aType = fo.type
                    
                    if objFeed.count > 0 {
                        ano.id = (objFeed.first?.name)!
                    } else {
                        ano.id = fo.feedId
                    }
                    
                    ano.name = fo.name
                    ano.title = ano.id + " - " + fo.name
                
                    mapView.addAnnotation(ano)
                    // TODO? Radius Overlay?
                } 
            }
        }
        
        
        for a in mapView.annotations {
            let objAtAnnotationLocation = feedObjects.filter( {$0.lat == a.coordinate.latitude && $0.lng == a.coordinate.longitude} )
            // TODO?: let activeInDB = objAtAnnotationLocation.filter({ !$0.active || $0.deleted })
            
            if objAtAnnotationLocation.count == 0 {
                print("Removing: " + String(a.coordinate.latitude))
                mapView.removeAnnotation(a)
            }
        }
        
        mapView.updateFocusIfNeeded()
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("locationManager")
        
        curLat = (locations.last?.coordinate.latitude)!
        curLng = (locations.last?.coordinate.longitude)!
        curAlt = (locations.last?.altitude)!
        
        do {
            try realm.write {
                session.first?.currentLat = curLat
                session.first?.currentLng = curLng
                session.first?.currentAlt = curAlt
            }
        } catch {
            print("Error: \(error)")
        }
        
        updateviewRadius()
    }
    
    
    @objc func mainUpdate() {
        if session.count > 0 {
            
            
            if updateTimer.timeInterval != (session.first?.mapUpdateInterval)!+1 {
                updateTimer.invalidate()
            }
            
            if !updateTimer.isValid {
                updateTimer = Timer.scheduledTimer(
                    timeInterval: (session.first?.mapUpdateInterval)!+1,
                    target: self, selector: #selector(mainUpdate),
                    userInfo: nil, repeats: true)
            }
            
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
        
        pinView?.image = UIImage(named: "pin_ds")
        pinView?.canShowCallout = true
        
        return pinView
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        view.image = UIImage(named: "pin_s")

    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        view.image = UIImage(named: "pin_ds")
    }
    
    
    func initMapView() {
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.showsPointsOfInterest = false
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.userLocation.title = ""
        mapView.tintColor = UIColor.black
        mapView.backgroundColor = UIColor.black
        
        if (session.first?.backgroundGps)! {
            locationManager.requestAlwaysAuthorization()
        }
//        else {
//            locationManager.requestWhenInUseAuthorization()
//        }

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = true
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
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear: MapVC" )
        reloadAnnotations()
    }

}
