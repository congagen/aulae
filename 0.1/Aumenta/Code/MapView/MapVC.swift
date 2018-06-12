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

    @IBOutlet var mapView: MKMapView!
    let locationManager = CLLocationManager()

    lazy var realm = try! Realm()
    lazy var session: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var sources: Results<RLM_Source> = { self.realm.objects(RLM_Source.self) }()
    
    var curLat = 0.0
    var curLng = 0.0
    
    
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
    
    
    func updateObjects(){
        
        for s in sources.filter({$0.active}) {
            let sOnMap = mapView.annotations.filter({$0.coordinate.latitude == s.lat && $0.coordinate.longitude == s.lng})
            
            if sOnMap.count == 0 {
                let ano = MapAno()
                ano.coordinate = CLLocationCoordinate2D(latitude: s.lat, longitude: s.lng)
                mapView.addAnnotation(ano)
                addRadiusOverlay(lat: s.lat, long: s.lng, radius: s.radius)
            }
        }
        
        for a in mapView.annotations {
            let sInData = sources.filter({$0.lat == a.coordinate.latitude && $0.lng == a.coordinate.longitude})
            
            if sInData.count == 0 {
                mapView.removeAnnotation(a)
                
                let overlays = mapView.overlays.filter({
                    $0.coordinate.latitude == a.coordinate.latitude && $0.coordinate.longitude == a.coordinate.longitude
                })
                
                if overlays.count > 0 {
                    for o in overlays {
                        mapView.remove(o)
                    }
                }
            }
        }
        
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear: MapVC" )
        updateObjects()
    }

}
