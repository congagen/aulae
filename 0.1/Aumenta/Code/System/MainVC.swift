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
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()

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
    
    
    func storeFeedObject(objInfo: [String : Any], objFilePath: URL) {
        let rlmObj = RLM_Obj()
        
        do {
            try realm.write {
                rlmObj.id = objInfo["id"] as! String
                rlmObj.name = objInfo["name"] as! String
                rlmObj.info = objInfo["info"] as! String
                rlmObj.filePath = objFilePath.absoluteString
                
                rlmObj.xPos = objInfo["pos_x"] as! Double
                rlmObj.yPos = objInfo["pos_y"] as! Double
                rlmObj.zPos = objInfo["pos_z"] as! Double
                
                rlmObj.xRot = objInfo["rot_x"] as! Double
                rlmObj.yRot = objInfo["rot_y"] as! Double
                rlmObj.zRot = objInfo["rot_z"] as! Double
                
                rlmObj.scale = objInfo["scale"] as! Double
                
                realm.add(rlmObj)
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    
    func updateFeedObjects(feedList: Dictionary<String, AnyObject>) {
        print("! updateFeedObjects !")

        for k in (feedList["content"]?.allKeys)! {
            
            let item = feedList["content"]![k] as! Dictionary<String, AnyObject>
            
            let objData: [String : Any] = [
                "name":   item["name"] as! String,
                "id":     item["id"] as! String,
                "info":   item["info"] as! String,
                "version":item["version"] as! Double,

                "url":    item["model_url"] as! String,
                
                "lat":    item["lat"] as! Double,
                "lng":    item["long"] as! Double,
                "radius": item["radius"] as! Double,
                
                "pos_x":  item["xPos"] as! Double,
                "pos_y":  item["yPos"] as! Double,
                "pos_z":  item["xPos"] as! Double,
                
                "rot_x":  item["xRot"] as! Double,
                "rot_y":  item["yRot"] as! Double,
                "rot_z":  item["zRot"] as! Double,
                
                "scale":  item["scale"] as! Double
            ]
            
            let objId = item["id"] as! String
            let version = item["version"] as! String
            let modelUrl = item["modelUrl"] as! String

            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
            let fileName = item["id"] as! String + documentsUrl.lastPathComponent!
            let destinationUrl = documentsUrl.appendingPathComponent(fileName)
            
            let idExists = feedObjects.filter( {$0.id == objId} ).count > 0
            let versionExists = feedObjects.filter( {$0.version == version} ).count > 0
            
            if !idExists && !versionExists {
                if let URL = URL(string: modelUrl) {
                    let _ = httpDl.loadFileAsync(
                        url: URL as URL,
                        destinationUrl: destinationUrl!,
                        completion: {
                            DispatchQueue.main.async {
                                self.storeFeedObject(objInfo: objData, objFilePath: destinationUrl!)
                            }
                    })
                }
            }
        }
    }
    
    
    func updateFeedDatabase(feedDbItem: RLM_Feed, feedspec: Dictionary<String, AnyObject>) {
        print("updateFeedDatabase")

        let sID: String = feedspec["id"] as! String
        let sName: String = feedspec["name"] as! String
        let sInfo: String = feedspec["info"] as! String
        let sVersion: String = feedspec["version"] as! String
        //let sUpdated_utx: String = feedspec["updated_utx"] as! String
    
        let date = Date()
        let currentUtx = Int(date.timeIntervalSince1970)
        
        do {
            try realm.write {
                feedDbItem.id = sID
                feedDbItem.name = sName
                feedDbItem.info = sInfo
                feedDbItem.version = sVersion
                feedDbItem.updatedUtx = currentUtx
            }
        } catch {
            print("Error: \(error)")
        }

    }
    
    
    func updateFeed(fileUrl: URL, feedDbItem: RLM_Feed) {
        if FileManager.default.fileExists(atPath: fileUrl.path) {
            do {
                let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                
                if let jsonResult = jsonResult as? Dictionary<String, AnyObject> {
                    
                    updateFeedDatabase(feedDbItem: feedDbItem, feedspec: jsonResult)
                    updateFeedObjects(feedList: jsonResult)
                    
                    
                    
//                    if jsonResult["version"] as! String != feedDbItem.version {
//                        updateFeedDatabase(feedDbItem: feedDbItem, feedspec: jsonResult)
//                        updateFeedObjects(feedList: jsonResult)
//                    }

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
        
        for fe in feeds {
            let timeSinceUpdate = abs(NSDate().timeIntervalSinceNow.distance(to: Double(fe.updatedUtx)))
            
            print("Time Since Update: " + String(timeSinceUpdate))
            print(String(fe.id) + " " + String(fe.active) + " " + String(fe.lat) + " " + String(fe.lng) + " " + String(fe.url))
            
            let fileName = fe.id + ".json"
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
            let destinationUrl = documentsUrl.appendingPathComponent(fileName)
            
            if Int(timeSinceUpdate) > updateInterval {
                print("TimeSinceUpdate > UpdateInterval")
                print("Updating... Dest URL: " + (destinationUrl?.path)! )
                print("FeedObjectCount: " + String(feedObjects.count))
                
                if let URL = URL(string: fe.url) {
                    let _ = httpDl.loadFileAsync(
                        url: URL as URL,
                        destinationUrl: destinationUrl!,
                        completion: {
                            DispatchQueue.main.async {
                                self.updateFeed(fileUrl: destinationUrl!, feedDbItem: fe)
                            }
                    })
                }
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
