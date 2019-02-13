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


class MapVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    var updateTimer = Timer()
    let updateInterval: Double = 10
    
    @IBOutlet var mapView: MKMapView!
    let locationManager = CLLocationManager()

    lazy var realm = try! Realm()
    lazy var session: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var feeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()

    var curLat = 0.0
    var curLng = 0.0
    
    var textField: UITextField? = nil

    @IBOutlet var addBtn: UIBarButtonItem!
    @IBAction func addBtnAction(_ sender: UIBarButtonItem) {
        showURLAlert(aMessage: "Yumm")
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
    
    
    func handleEnterURL(alertView: UIAlertAction!) {
        let newFeed = RLM_Feed()
        
        do {
            try realm.write {
                if textField?.text != nil {
                    if feeds.filter({$0.url == (self.textField?.text)! }).count == 0 {
                        
                        if (self.textField?.text)! != "" {
                            newFeed.id = UUID().uuidString
                            newFeed.name = "Updating..."
                            
                            self.realm.add(newFeed)
                        }
                        
                    } else {
                        print("feeds.filter({$0.id == (self.textField?.text)! }).count > 0")
                    }
                }
            }
        } catch {
            print("Error: \(error)")
        }
        
        mainUpdate()

    }
    
    
    func urlConfigurationTextField(textField: UITextField!)
    {
        if let _ = textField {
            self.textField = textField!
            textField.text! = (session.first?.debugUrl)!
        }
    }
    
    
    func showURLAlert(aMessage: String?){
        let alert = UIAlertController(
            title: "Feed URL",
            message: "",
            preferredStyle: UIAlertControllerStyle.alert
        )
        
        // TODO: Add Name Field
        
        alert.addTextField(configurationHandler: urlConfigurationTextField)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler:handleCancel))
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler:handleEnterURL))
        
        alert.view.tintColor = UIColor.black
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    func addRadiusOverlay(lat:Double, long:Double, radius:Double) {
        
        let currentOverlays = mapView.overlays.filter {
            $0.coordinate.latitude == lat && $0.coordinate.longitude == long
        }
        
        let locat: CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat, long)
        
        if currentOverlays.count == 0 {
            let areaCircle = MKCircle(center: locat, radius: Double(radius))
            mapView.add(areaCircle)
        }
    }
    
    
    func reloadAnnotations(){
        let filterA = mapView.annotations.filter( {$0.isKind(of: MapAno.self)} )

        for a in filterA {
            mapView.removeAnnotation(a)
        }
        
        updateObjectAnnotations()
    }
    
    
    
    func updateObjectAnnotations(){
        print("updateObjectAnnotations")
        
        for fo in feedObjects {
            if fo.active && !fo.deleted {
                // Omitt location marker
                // a.isKind(of: MKUserLocation)
                let filterA = mapView.annotations.filter( {$0.isKind(of: MapAno.self)} )
                let fOnMap = filterA.filter( {$0.coordinate.latitude == fo.lat && $0.coordinate.longitude == fo.lng} )
                
                print("FeedObject: " + String(fo.lat) + ", " + String(fo.lng))
                
                if fOnMap.count == 0 {
                    print("Adding annotation: " + String(fo.id) )
                    let ano = MapAno()
                    ano.coordinate = CLLocationCoordinate2D(latitude: fo.lat, longitude: fo.lng)
                    ano.name = fo.name
                    ano.id = fo.id
                    ano.title = fo.feedId
                
                    mapView.addAnnotation(ano)
                    //addRadiusOverlay(lat: fo.lat, long: fo.lng, radius: fo.radius) //TODO
                } 
            }
        }
        
        
        for a in mapView.annotations {
            let objAtAnnotationLocation = feedObjects.filter( {$0.lat == a.coordinate.latitude && $0.lng == a.coordinate.longitude} )
            //let activeInDB = objAtAnnotationLocation.filter({ !$0.active || $0.deleted })
            
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
        
        do {
            try realm.write {
                session.first?.currentLat = curLat
                session.first?.currentLng = curLng
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        pinView?.canShowCallout = true
        pinView?.pinTintColor = UIColor.purple
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Location")
            pinView?.canShowCallout = false
            pinView!.pinTintColor = UIColor.black
        } else {
            pinView?.pinTintColor = UIColor.purple
            pinView!.annotation = MapAno()
            pinView?.canShowCallout = false
        }
        
        return pinView
        
    }
    
    
    
    @objc func mainUpdate() {
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
            
            updateObjectAnnotations()
        }
    }
    
    
    func initMapView() {
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.showsPointsOfInterest = false
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.userLocation.title = ""
        
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = true
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initMapView()
        mainUpdate()
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear: MapVC" )
        reloadAnnotations()

    }

}
