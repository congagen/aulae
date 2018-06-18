//
//  FeedMgmt.swift
//  Aumenta
//
//  Created by Tim Sandgren on 2018-06-18.
//  Copyright © 2018 Abstraqata. All rights reserved.
//

import Foundation

extension MainVC {
    
    
    func storeFeedObject(objInfo: [String : Any], objFilePath: URL) {
        let rlmObj = RLM_Obj()
        
        do {
            try realm.write {
                rlmObj.id = objInfo["id"] as! String
                rlmObj.name = objInfo["name"] as! String
                rlmObj.info = objInfo["info"] as! String
                rlmObj.filePath = objFilePath.absoluteString
                
                rlmObj.lat = objInfo["lat"] as! Double
                rlmObj.lng = objInfo["lng"] as! Double
                
                rlmObj.x_pos = objInfo["pos_x"] as! Double
                rlmObj.y_pos = objInfo["pos_y"] as! Double
                rlmObj.z_pos = objInfo["pos_z"] as! Double
                
                rlmObj.x_rot = objInfo["rot_x"] as! Double
                rlmObj.y_rot = objInfo["rot_y"] as! Double
                rlmObj.z_rot = objInfo["rot_z"] as! Double
                
                rlmObj.scale = objInfo["scale"] as! Double
                
                realm.add(rlmObj)
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    
    func validateObj(keyList: [String], dict: Dictionary<String, AnyObject>) -> Bool {
        var valid = true
        
        for k in keyList {
            if dict.keys.contains(k) == false {
                valid = false
            }
        }
        
        return valid
    }
    
    
    func valudIfPresent(dict:Dictionary<String, AnyObject>, key: String, placeHolderValue: Any) -> Any {
        
        if dict.keys.contains(key) {
            return dict[key]!
        } else {
            return placeHolderValue
        }
        
    }
    
    
    
    func updateFeedObjects(feedList: Dictionary<String, AnyObject>) {
        print("! updateFeedObjects !")
        
        for k in (feedList["content"]?.allKeys)! {
            
            let feedContent = feedList["content"]![k] as! Dictionary<String, AnyObject>
            
            let vKeys = ["name", "id", "version", "model_url"]
            let valid = validateObj(keyList: vKeys, dict: feedContent)
            
            if valid {
                let objData: [String : Any] = [
                    "name":     feedContent["name"] as! String,
                    "id":       feedContent["id"] as! String,
                    "version":  feedContent["version"] as! Int,
                    "url":      feedContent["model_url"] as! String,
                    
                    "info":   valudIfPresent(dict: feedContent, key: "info",    placeHolderValue: ""),
                    
                    "lat":    valudIfPresent(dict: feedContent, key: "lat",    placeHolderValue: 0.0),
                    "lng":    valudIfPresent(dict: feedContent, key: "long",   placeHolderValue: 0.0),
                    "radius": valudIfPresent(dict: feedContent, key: "radius", placeHolderValue: 1.0),
                    
                    "pos_x":  valudIfPresent(dict: feedContent, key: "x_pos",   placeHolderValue: 0.0),
                    "pos_y":  valudIfPresent(dict: feedContent, key: "y_pos",   placeHolderValue: 0.0),
                    "pos_z":  valudIfPresent(dict: feedContent, key: "z_pos",   placeHolderValue: 1.0),
                    
                    "rot_x":  valudIfPresent(dict: feedContent, key: "x_rot",   placeHolderValue: 0.0),
                    "rot_y":  valudIfPresent(dict: feedContent, key: "y_rot",   placeHolderValue: 0.0),
                    "rot_z":  valudIfPresent(dict: feedContent, key: "z_rot",   placeHolderValue: 0.0),
                    
                    "scale":  valudIfPresent(dict: feedContent, key: "scale",  placeHolderValue: 1.0)
                ]
                
                let objId =    feedContent["id"] as! String
                let version =  feedContent["version"] as! Int
                let modelUrl = feedContent["model_url"] as! String
                
                let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
                let fileName = (URL(string: modelUrl)?.lastPathComponent)!
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
            } else {
                // TODO: Update error count for feed
            }
            
        }
    }
    
    
    func updateFeedDatabase(feedDbItem: RLM_Feed, feedspec: Dictionary<String, AnyObject>) {
        print("updateFeedDatabase")
        
        let sID: String = feedspec["id"] as! String
        let sName: String = feedspec["name"] as! String
        let sInfo: String = feedspec["info"] as! String
        let sVersion: Int = feedspec["version"] as! Int
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
        print("UpdateFeed")
        
        if FileManager.default.fileExists(atPath: fileUrl.path) {
            do {
                let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                
                if let jsonResult = jsonResult as? Dictionary<String, AnyObject> {
                    
                    if jsonResult.keys.contains("version") {
                        if jsonResult["version"] as! Int != feedDbItem.version {
                            updateFeedDatabase(feedDbItem: feedDbItem, feedspec: jsonResult)
                            updateFeedObjects(feedList: jsonResult)
                        }
                    } else {
                        updateFeedDatabase(feedDbItem: feedDbItem, feedspec: jsonResult)
                        updateFeedObjects(feedList: jsonResult)
                        print("Missing key: VERSION")
                        // TODO: Increment error count?
                    }
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
            let timeSinceUpdate = abs(NSDate().timeIntervalSince1970.distance(to: Double(fe.updatedUtx)))
            
            print("Time Since Update: " + String(timeSinceUpdate))
            print(String(fe.id) + " " + String(fe.active) + " " + String(fe.lat) + " " + String(fe.lng) + " " + String(fe.url))
            print("FeedObjectCount: " + String(feedObjects.count))
            
            for ob in feedObjects {
                print(ob.filePath)
            }
            
            let fileName = fe.id + ".json"
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
            let destinationUrl = documentsUrl.appendingPathComponent(fileName)
            
            if Int(timeSinceUpdate) > updateInterval {
                
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
    
    
}
