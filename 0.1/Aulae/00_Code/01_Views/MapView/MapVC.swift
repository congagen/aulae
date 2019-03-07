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

    let imageColor = UIColor(red: 0.1, green: 0.9, blue: 0.5, alpha: 0.7)
    let gifColor   = UIColor(red: 0.2, green: 0.8, blue: 0.6, alpha: 0.7)
    let objColor   = UIColor(red: 0.4, green: 0.8, blue: 0.7, alpha: 0.7)
    let usdzColor  = UIColor(red: 0.6, green: 0.7, blue: 0.8, alpha: 0.7)
    let audioColor = UIColor(red: 0.5, green: 0.6, blue: 0.9, alpha: 0.7)
    let textColor  = UIColor(red: 0.6, green: 0.5, blue: 1.0, alpha: 0.7)
    
    var userSearchRadiusIndicator: MKCircle = MKCircle()

    var selected: RLM_Obj? = nil
    var textField: UITextField? = nil
    
    @IBOutlet var reloadBtn: UIBarButtonItem!
    @IBAction func reloadBtnAction(_ sender: UIBarButtonItem) {
        initMapView()
        mainUpdate()
        updateObjectAnnotations()
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
        updateSearchRadius()

    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(circle: overlay as! MKCircle)
        circleRenderer.fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.05)
        circleRenderer.strokeColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5)
        circleRenderer.lineWidth = 1
        
        return circleRenderer
    }
    
    
    func updateSearchRadius() {
        
        mapView.removeOverlay(userSearchRadiusIndicator)
        
        let cLoc = CLLocationCoordinate2D(
            latitude: mapView.userLocation.coordinate.latitude,
            longitude: mapView.userLocation.coordinate.longitude
        )
        
        if (session.first?.searchRadius)! >= 110000 {
            userSearchRadiusIndicator = MKCircle(center: cLoc, radius: Double( (session.first?.searchRadius)! - 100000 ))
        } else {
            userSearchRadiusIndicator = MKCircle(center: cLoc, radius: Double( (session.first?.searchRadius)! ))
        }
        
        mapView.addOverlay(userSearchRadiusIndicator)
        
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
    
    
    func addAnoRadius(feObj: RLM_Obj) {
        let cLoc = CLLocationCoordinate2D( latitude: feObj.lat, longitude: feObj.lng )
        
        if (session.first?.searchRadius)! >= 110000 {
            userSearchRadiusIndicator = MKCircle(center: cLoc, radius: Double( (feObj.radius) - 100000 ))
        } else {
            userSearchRadiusIndicator = MKCircle(center: cLoc, radius: Double( (feObj.radius) ))
        }
        
        mapView.addOverlay(userSearchRadiusIndicator)
        
    }

    
    func updateObjectAnnotations() {
        print("updateObjectAnnotations")
        
        let filterA = mapView.annotations.filter( {$0.isKind(of: MapAno.self)} )
        
        for a in filterA {
            mapView.removeAnnotation(a)
        }
        
        for o in mapView.overlays {
            mapView.removeOverlay(o)
        }
        
        for fObj in feedObjects {
            if fObj.active && !fObj.deleted {
                let objFeed = feeds.filter( {$0.id == fObj.feedId && !$0.deleted} )
                
                if objFeed.count > 0 {
                    let ano = MapAno()
                    
                    ano.coordinate = CLLocationCoordinate2D(latitude: fObj.lat, longitude: fObj.lng)
                    ano.aType      = fObj.type
                    ano.id         = fObj.uuid
                    ano.name       = fObj.name
                    
                    ano.title    = fObj.name
                    ano.subtitle = (objFeed.first?.name)!
        
                    if fObj.radius > 0 {
                        addAnoRadius(feObj: fObj)
                    }
                    
                    mapView.addAnnotation(ano)
                }
            }
        }
        
        updateSearchRadius()
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
            mapView.view(for: annotation)?.tintColor = UIColor.black
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
        pinView?.backgroundColor = UIColor.clear
        
        let pinIcon = UIImageView()
        
        pinIcon.frame = CGRect(
            x: (pinView?.frame.width)! * 0, y: (pinView?.frame.height)! * 0,
            width: (pinView?.frame.width)!, height: (pinView?.frame.height)!
        )
        
        pinIcon.layer.cornerRadius = pinIcon.frame.width / 2;
        pinIcon.layer.masksToBounds = true
        pinIcon.backgroundColor = UIColor.black
        
        if let o: MapAno = annotation as? MapAno {
            let fo = feedObjects.filter( {$0.uuid == o.id } )
            
            if fo.count > 0 {
                pinIcon.backgroundColor = UIColor(hexColor: (fo.first?.hex_color)!)
                pinView?.addSubview(pinIcon)
                
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
        mapView.showsPointsOfInterest = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsBuildings = true
        mapView.userLocation.title = ""
        mapView.tintColor = UIColor.black
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
        updateObjectAnnotations()
    }

}
