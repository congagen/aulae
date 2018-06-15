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
    lazy var feeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    
    var mainUpdateTimer = Timer()
    var activeDownloads: [String: String] = [:]
    
    let httpDl = HttpDownloader()
    
    
    func updateSession(){
        
        // If near and notify -> Send notification
        
    }

    func handler(a:String, b:String) {
        
    }
    
    func randRange (lower: Int , upper: Int) -> Int {
        return Int(arc4random_uniform(UInt32(upper - lower)))
    }
    
    
    func updateFeedObjects(feedList: Dictionary<String, AnyObject>) {
        for k in feedList["content"] as! Dictionary<String, AnyObject> {
            print(feedList["content"]![k])
        }
    }
    
    
    func updateFeedDatabase(feedspec: Dictionary<String, AnyObject>) {
        print("updateFeedDatabase")
        var sObject = RLM_Feed()

        let sID: String = feedspec["id"] as! String
        let sName: String = feedspec["name"] as! String
        let sInfo: String = feedspec["info"] as! String
        let sVersion: String = feedspec["version"] as! String
        //let sUpdated_utx: String = feedspec["updated_utx"] as! String
    
        let date = Date()
        let currentUtx = Int(date.timeIntervalSince1970)
        
        let fd = feeds.filter( {$0.id == sID} )
        if  fd.count > 0 {
            if fd.first?.version != sVersion {
                sObject = (fd.first)!
                updateFeedObjects(feedList: feedspec)
            }
        }
    
        do {
            try realm.write {
                sObject.id = sID
                sObject.name = sName
                sObject.info = sInfo
                sObject.version = sVersion
                sObject.updatedUtx = currentUtx
                
                updateFeedObjects(feedList: feedspec)
                
                if fd.count < 1 {
                    realm.add(sObject)
                }
                
            }
        } catch {
            print("Error: \(error)")
        }

    }
    
    
    func updateFeed(fileUrl: URL, id: String) {
        if FileManager.default.fileExists(atPath: fileUrl.path) {
            do {
                let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                
                if let jsonResult = jsonResult as? Dictionary<String, AnyObject> {
                    updateFeedDatabase(feedspec: jsonResult)
                }
            } catch {
                print(error)
            }
        }
    }
    
    
    func updateFeeds() {
        print("updateFeeds")
        // Download JSON if [ "MISSING" || "TIME SINCE LAST UPDATE" > N ]
        // Download Objects if distance < N
        
        let updateInterval = 10 //randRange(lower: 3, upper: 5)
        
        for s in feeds {
            let timeSinceUpdate = abs(NSDate().timeIntervalSince1970.distance(to: Double(s.updatedUtx)))
            
            print("Time Since Update: " + String(timeSinceUpdate))
            print(String(s.id) + " " + String(s.active) + " " + String(s.lat) + " " + String(s.lng) + " " + String(s.url))
            
            let fileName = s.id + ".json"
            
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
            let destinationUrl = documentsUrl.appendingPathComponent(fileName)
            
            if Int(timeSinceUpdate) > updateInterval {
                print("timeSinceUpdate > updateInterval")
                print("Updating... Dest URL: " + (destinationUrl?.path)! )
                
                if let URL = URL(string: s.url) {
                    let _ = httpDl.loadFileAsync(
                        url: URL as URL,
                        destinationUrl: destinationUrl!,
                        completion: {
                            DispatchQueue.main.async {
                                self.updateFeed(fileUrl: destinationUrl!, id: s.id)
                            }
                            
                    }
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
        
        DispatchQueue.main.async {
            self.updateFeeds()
        }

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
