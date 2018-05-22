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

class MapVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet var mapView: MKMapView!
    let locationManager = CLLocationManager()

    var curLat = 0.0
    var curLng = 0.0
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        curLat = (locations.last?.coordinate.latitude)!
        curLng = (locations.last?.coordinate.longitude)!
    }
    
    
    func initMapView() {
        mapView.delegate = self
        mapView.showsUserLocation = false
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
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
