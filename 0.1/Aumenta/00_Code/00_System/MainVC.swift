//
//  MainVC.swift
//  ArkitTest
//
//  Created by Tim Sandgren on 2018-05-22.
//  Copyright © 2018 Abstraqata. All rights reserved.
//

import UIKit
import Realm
import MapKit
import RealmSwift

class MainVC: UITabBarController, CLLocationManagerDelegate {

    lazy var realm = try! Realm()
    lazy var session: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var feeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
    
    let locationManager = CLLocationManager()
    
    let validObjectJsonKeys = ["name", "id", "version", "type", "style"]
    
    var mainUpdateTimer = Timer()
    var activeDownloads: [String: String] = [:]
    
    let httpDl = HttpDownloader()
    
    
    func randRange (lower: Int , upper: Int) -> Int {
        return Int(arc4random_uniform(UInt32(upper - lower)))
    }
    
    
    @objc func mainUpdate() {
        print("mainUpdate: MainVC")
        dbGc()

        if session.count > 0 {
            if mainUpdateTimer.timeInterval != session.first?.contentUpdateInterval {
                mainUpdateTimer.invalidate()
            }
            
            if !mainUpdateTimer.isValid {
                mainUpdateTimer = Timer.scheduledTimer(
                    timeInterval: session[0].contentUpdateInterval,
                    target: self, selector: #selector(mainUpdate),
                    userInfo: nil, repeats: true)
            }
        }
        
        DispatchQueue.main.async {
            self.updateFeeds()
        }

    }
    
    
    func dbGc(){
        print("dbGc")

        do {
            try realm.write {
                for f in feeds {
                    if f.deleted {
                        realm.delete(f)
                    }
                }
                
                for o in feedObjects {
                    if o.deleted {
                        realm.delete(o)
                    }
                }
            }
        } catch {
            print("Error: \(error)")
        }

    }
    
    
    func resetErrCounts()  {
        print("resetErrCounts")
        for f in feeds {
            do {
                try realm.write {
                    f.errors = 0
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }
    

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("locationManager")

        do {
            try realm.write {
                session.first?.currentLat = (locations.last?.coordinate.latitude)!
                session.first?.currentLng = (locations.last?.coordinate.longitude)!
                session.first?.currentAlt = (locations.last?.altitude)!
            }
        } catch {
            print("Error: \(error)")
        }
        
    }
    
    
    func initLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        if (session.first?.backgroundGps)! {
            locationManager.requestAlwaysAuthorization()
            locationManager.allowsBackgroundLocationUpdates = true
        } else {
            locationManager.requestWhenInUseAuthorization()
            locationManager.allowsBackgroundLocationUpdates = false
        }
        
    }
    
    
    func initSession(){
        dbGc()
        
        if session.count < 1 {
            let sess = RLM_Session()
            
            do {
                try realm.write {
                    self.realm.add(sess)
                }
            } catch {
                print("Error: \(error)")
            }
        }
        
        resetErrCounts()
        mainUpdate()
        initLocation()
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSession()
        
        if let viewControllers = tabBarController?.viewControllers {
            for viewController in viewControllers {
                let _ = viewController.view
                viewControllers.forEach { $0.view.updateConstraints() }
            }
        }

    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}
