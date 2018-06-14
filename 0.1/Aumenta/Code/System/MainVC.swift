//
//  MainVC.swift
//  ArkitTest
//
//  Created by Tim Sandgren on 2018-05-22.
//  Copyright © 2018 Abstraqata. All rights reserved.
//

import UIKit
import Realm
import RealmSwift

class MainVC: UITabBarController {

    lazy var realm = try! Realm()
    
    lazy var session: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var sources: Results<RLM_Source> = { self.realm.objects(RLM_Source.self) }()
    
    var mainUpdateTimer = Timer()
    
    var downloads: [String: RLM_Source] = [:]
    
    let httpDl = HttpDownloader()
    
    
    func updateSession(){
        
        // If near and notify -> Send notification
        
    }

    func handler(a:String, b:String) {
        
    }
    
    func randRange (lower: Int , upper: Int) -> Int {
        return Int(arc4random_uniform(UInt32(upper - lower)))
    }
    
    
    func ummm(ah: URL) {
        
        print("File: " + String(ah.absoluteString))
        
        if FileManager.default.fileExists(atPath: ah.path) {
            //let path = Bundle.main.path(forResource: ah.path, ofType: ah.pathExtension)
            
            do {
                let data = try Data(contentsOf: ah, options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                
                if let jsonResult = jsonResult as? Dictionary<String, AnyObject> {
                    print(jsonResult)
                } else {
                    print("!jsonResult")
                }
            } catch {
                print(error)
            }
            
            
//            } else {
//                print("ERROR " + String(ah.path) + " ERROR")
//            }
        }
    }
    
    
    func updateSources() {
        // Download JSON if [ "MISSING" || "TIME SINCE LAST UPDATE" > N ]
        // Download Objects if distance < N
        
        let updateInterval = randRange(lower: 3, upper: 5)
        
        for s in sources {
            let timeSinceUpdate = abs(NSDate().timeIntervalSince1970.distance(to: Double(s.updatedUtx)))
            
            print("Time Since Update: " + String(timeSinceUpdate))
            print(String(s.id) + " " + String(s.active) + " " + String(s.lat) + " " + String(s.lng) + " " + String(s.url))
            
            let fileName = s.id + ".json"
            
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
            let destinationUrl = documentsUrl.appendingPathComponent(fileName)
            
            if Int(timeSinceUpdate) > updateInterval {
                print("Dest URL: " + (destinationUrl?.path)! )
                
                if let URL = URL(string: s.url) {
                    let f = httpDl.loadFileAsync(
                        url: URL as URL,
                        destinationUrl: destinationUrl!,
                        completion: { self.ummm(ah: destinationUrl!) }
                    )
                }
            }
            
            do {
                try realm.write {
                    s.updatedUtx = abs(Int(NSDate().timeIntervalSince1970))
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    
    @objc func mainUpdate() {
        print("mainUpdate: MainVC")
        
        if session.count > 0 {
            if mainUpdateTimer.timeInterval != session.first?.updateInterval {
                mainUpdateTimer.invalidate()
            }
            
            if !mainUpdateTimer.isValid {
                mainUpdateTimer = Timer.scheduledTimer(
                    timeInterval: session[0].updateInterval,
                    target: self, selector: #selector(mainUpdate),
                    userInfo: nil, repeats: true)
            }
        }
        
        updateSources()
    }
    
    
    func initSession(){
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
        
        mainUpdate()
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
