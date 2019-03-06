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
    lazy var session: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var feeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()

    var selected: RLM_Obj? = nil
    
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
        reloadAnnotations()
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
        
        var areaCircle: MKCircle
        
        if (session.first?.searchRadius)! >= 11000 {
            areaCircle = MKCircle(center: cLoc, radius: Double( (session.first?.searchRadius)! - 10000 ))
        } else {
            areaCircle = MKCircle(center: cLoc, radius: Double( (session.first?.searchRadius)! ))
        }
        
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
                    ano.id = fo.id
                    ano.name = fo.name
                    
                    if objFeed.count > 0 {
                        ano.title = (objFeed.first?.name)!
                        ano.subtitle = fo.name
                    } else {
                        ano.title = fo.name
                    }
                    
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
    
    
    @objc func mainUpdate() {
        if session.count > 0 {
            let uIv = (session.first?.mapUpdateInterval)! + 1
            
            if updateTimer.timeInterval != uIv {
                updateTimer.invalidate()
            }
            
            if !updateTimer.isValid {
                updateTimer = Timer.scheduledTimer(
                    timeInterval: uIv,
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
        
        if let o: MapAno = annotation as? MapAno {
            let fo = feedObjects.filter( {$0.id == o.id } )
            
            if fo.count > 0 {
                let subtitleLabel = UILabel()
                
                if fo.first?.name != "" {
                    subtitleLabel.text = fo.first?.name
                    subtitleLabel.numberOfLines = 0
                    subtitleLabel.font = UIFont.systemFont(ofSize: 12)
                    subtitleLabel.textColor = UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0.5)
                    subtitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
                    pinView!.detailCalloutAccessoryView = subtitleLabel
                }
            }
        }
        
        return pinView
    }
    
    
    func getAnoObj(view: MKAnnotationView) -> RLM_Obj? {
        if let a: MapAno = view.annotation as? MapAno {
            let id      = a.id
            let results = feedObjects.filter({$0.id == id})
            
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
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        view.image = UIImage(named: "pin_s")
        
        if getAnoObj(view: view) != nil {
            selected = getAnoObj(view: view)!
            print(selected!)
        }
    }
    
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        view.image = UIImage(named: "pin_ds")
        
        if getAnoObj(view: view) != nil {
            selected = getAnoObj(view: view)!
            print(selected!)
        }
    }
    
    
    func initMapView() {
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.showsPointsOfInterest = false
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.userLocation.title = ""
        mapView.tintColor = view.superview?.tintColor
        mapView.backgroundColor = UIColor.black
        
//        if (session.first?.backgroundGps)! {
//            locationManager.requestAlwaysAuthorization()
//            locationManager.allowsBackgroundLocationUpdates = true
//        } else {
//            locationManager.requestWhenInUseAuthorization()
//            locationManager.allowsBackgroundLocationUpdates = false
//        }
//
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.startUpdatingLocation()

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

    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear: MapVC" )
        reloadAnnotations()
    }

}
