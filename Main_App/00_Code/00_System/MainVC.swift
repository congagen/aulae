//
//  MainVC.swift
//  ArkitTest
//
//  Created by Tim Sandgren on 2018-05-22.
//  Copyright © 2018 Abstraqata. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation
import Realm
import RealmSwift

class MainVC: UITabBarController, CLLocationManagerDelegate {

    lazy var realm = try! Realm()
    lazy var rlmSystem: Results<RLM_SysSettings> = { self.realm.objects(RLM_SysSettings.self) }()
    lazy var rlmSession: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var rlmChatSession: Results<RLM_ChatSession> = { self.realm.objects(RLM_ChatSession.self) }()

    lazy var rlmCamera: Results<RLM_Camera> = { self.realm.objects(RLM_Camera.self) }()

    lazy var rlmFeeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
    
    let feedMgr = FeedMgmt()
    let locationManager = CLLocationManager()
    var mainUpdateTimer = Timer()
    var activeDownloads: [String: String] = [:]
        
    let httpDl = HttpDownloader()
    
    func randRange (lower: Int , upper: Int) -> Int {
        return Int(arc4random_uniform(UInt32(upper - lower)))
    }
    
    
    @objc func mainUpdate() {
        print("mainUpdate: MainVC")
        dbGc()

        if rlmSession.count > 0 {
            if mainUpdateTimer.timeInterval != rlmSession.first?.sysUpdateInterval {
                mainUpdateTimer.invalidate()
            }
            
            if !mainUpdateTimer.isValid {
                mainUpdateTimer = Timer.scheduledTimer(
                    timeInterval: (rlmSession.first?.sysUpdateInterval)!,
                    target: self, selector: #selector(mainUpdate),
                    userInfo: nil, repeats: true)
            }
        }
        
        DispatchQueue.main.async {
            self.feedMgr.updateFeeds(checkTimeSinceUpdate: true)
        }
        
        do {
            try realm.write {
                rlmSession.first!.showPlaceholders = (CLLocationManager.locationServicesEnabled() && rlmSession.first!.showPlaceholders)
            }
        } catch {
            print("Error: \(error)")
        }

    }
    
    
    func dbGc(){
        print("dbGc")

        do {
            try realm.write {
                for f in rlmFeeds {
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
        for f in rlmFeeds {
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
                rlmSession.first?.currentLat = (locations.last?.coordinate.latitude)!
                rlmSession.first?.currentLng = (locations.last?.coordinate.longitude)!
                rlmSession.first?.currentAlt = (locations.last?.altitude)!
            }
        } catch {
            print("Error: \(error)")
        }
        
    }
    
    
    func initLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        locationManager.requestWhenInUseAuthorization()
        locationManager.allowsBackgroundLocationUpdates = false
    }
    
    
    func initSession() {
        dbGc()
        
        if rlmSystem.count < 1 {
            let rlmSys = RLM_SysSettings()
            do {
                try realm.write {
                    self.realm.add(rlmSys)
                }
            } catch {
                print("Error: \(error)")
            }
        }
        
        
        if rlmCamera.count < 1 {
            let camSettings = RLM_Camera()
            do {
                try realm.write {
                    self.realm.add(camSettings)
                }
            } catch {
                print("Error: \(error)")
            }
        }
        
        if rlmChatSession.count < 1 {
            let chatSess = RLM_ChatSession()
            do {
                try realm.write {
                    self.realm.add(chatSess)
                    rlmChatSession.first!.sessionUUID = UUID().uuidString
                }
            } catch {
                print("Error: \(error)")
            }
        }
        
        if rlmSession.count < 1 {
            
            let sess = RLM_Session()
            do {
                try realm.write {
                    self.realm.add(sess)
                    rlmSession.first!.sessionUUID = UUID().uuidString
                }
            } catch {
                print("Error: \(error)")
            }
            
            quickStartExamples()
            contentExamples()
            
            resetErrCounts()
            mainUpdate()
            initLocation()
            
        } else {
            resetErrCounts()
            mainUpdate()
            initLocation()
        }
        
        do {
            try realm.write {
                rlmSession.first!.sessionUUID = UUID().uuidString
            }
        } catch {
            print("Error: \(error)")
        }
        
    }
    
    
//    override func transition(from fromViewController: UIViewController, to toViewController: UIViewController, duration: TimeInterval, options: UIView.AnimationOptions = [], animations: (() -> Void)?, completion: ((Bool) -> Void)? = nil) {
//        if let v: ARViewer = toViewController as? ARViewer {
//            v.loadingView.isHidden = false
//            v.manageLoadingScreen(interval: 2)
//        }
//    }
    
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.selectedIndex = 1
        UIOps().updateTabUIMode(tabCtrl: self)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        UIOps().updateTabUIMode(tabCtrl: self)
    }
    
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        UIOps().updateTabUIMode(tabCtrl: self)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}
