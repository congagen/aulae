//
//  FeedMgmt.swift
//  Aumenta
//
//  Created by Tim Sandgren on 2018-06-18.
//  Copyright © 2018 Abstraqata. All rights reserved.
//

import Foundation

extension MainVC {
    
    
    func storeFeedObject(objInfo: [String : Any], objFilePath: URL, originFeed:String) {
        let rlmObj = RLM_Obj()
        
        do {
            try realm.write {
                rlmObj.id = objInfo["id"] as! String
                rlmObj.feedId = originFeed

                rlmObj.name = objInfo["name"] as! String
                rlmObj.info = objInfo["info"] as! String
                rlmObj.filePath = objFilePath.absoluteString
                
                // TODO: rlmObj.lat = objInfo["lat"] as! Double
                // TODO: rlmObj.lng = objInfo["lng"] as! Double
                
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
    
    
    func valueIfPresent(dict:Dictionary<String, AnyObject>, key: String, placeHolderValue: Any) -> Any {
        
        if dict.keys.contains(key) {
            return dict[key]!
        } else {
            return placeHolderValue
        }
        
    }
    
    
    
    func updateFeedObjects(feedList: Dictionary<String, AnyObject>, feedId: String) {
        print("! updateFeedObjects !")
        
        
        for k in (feedList["content"]?.allKeys)! {
            
            let feedContent = feedList["content"]![k] as! Dictionary<String, AnyObject>
            let vKeys = ["name", "id", "version", "model_url"]
            let valid = validateObj(keyList: vKeys, dict: feedContent)
            
            // updated_utx
            if valid {
                let objData: [String : Any] = [
                    "name":         feedContent["name"] as! String,
                    "id":           feedContent["id"] as! String,
                    "feed_id":      feedId,

                    "version":      feedContent["version"] as! Int,
                    "url":          feedContent["model_url"] as! String,
                    
                    "info":   valueIfPresent(dict: feedContent, key: "info",    placeHolderValue: ""),
                    
                    "lat":    valueIfPresent(dict: feedContent, key: "lat",     placeHolderValue: 0.0),
                    "lng":    valueIfPresent(dict: feedContent, key: "long",    placeHolderValue: 0.0),
                    "radius": valueIfPresent(dict: feedContent, key: "radius",  placeHolderValue: 1.0),
                    
                    "pos_x":  valueIfPresent(dict: feedContent, key: "x_pos",   placeHolderValue: 0.0),
                    "pos_y":  valueIfPresent(dict: feedContent, key: "y_pos",   placeHolderValue: 0.0),
                    "pos_z":  valueIfPresent(dict: feedContent, key: "z_pos",   placeHolderValue: 1.0),
                    
                    "rot_x":  valueIfPresent(dict: feedContent, key: "x_rot",   placeHolderValue: 0.0),
                    "rot_y":  valueIfPresent(dict: feedContent, key: "y_rot",   placeHolderValue: 0.0),
                    "rot_z":  valueIfPresent(dict: feedContent, key: "z_rot",   placeHolderValue: 0.0),
                    
                    "scale":  valueIfPresent(dict: feedContent, key: "scale",  placeHolderValue: 1.0)
                ]
                
                let modelUrl = feedContent["model_url"] as! String
                let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
                let fileName = (URL(string: modelUrl)?.lastPathComponent)!
                let destinationUrl = documentsUrl.appendingPathComponent(fileName)
                
                if let URL = URL(string: modelUrl) {
                    let _ = httpDl.loadFileAsync(
                        url: URL as URL, destinationUrl: destinationUrl!,
                        completion: { DispatchQueue.main.async {
                            self.storeFeedObject(objInfo: objData, objFilePath: destinationUrl!, originFeed: feedId )} })
                }
            } else {
                // TODO: Update error count for feed
            }
            
        }
    }
    
    
    func updateFeedDatabase(feedDbItem: RLM_Feed, feedSpec: Dictionary<String, AnyObject>) {
        print("updateFeedDatabase")
        
        let vKeys = ["id", "name", "version", "updated_utx", "content"]
        let valid = validateObj(keyList: vKeys, dict: feedSpec)
        
        if valid {
            let sID: String = feedSpec["id"] as! String
            let sName: String = feedSpec["name"] as! String
            let sVersion: Int = feedSpec["version"] as! Int
            let sUpdated_utx: Int = feedSpec["updated_utx"] as! Int
            
            let sInfo: String = valueIfPresent(dict: feedSpec, key: "info", placeHolderValue: "") as! String
            
            // let date = Date()
            // let currentUtx = Int(date.timeIntervalSince1970)
            
            do {
                try realm.write {
                    feedDbItem.id = sID
                    feedDbItem.name = sName
                    feedDbItem.info = sInfo
                    feedDbItem.version = sVersion
                    feedDbItem.updatedUtx = (sUpdated_utx)
                }
            } catch {
                print("Error: \(error)")
            }
        } else {
            print("Feed Validation Error: " + String(feedDbItem.url))
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
                            updateFeedDatabase(feedDbItem: feedDbItem, feedSpec: jsonResult)
                            updateFeedObjects(feedList: jsonResult, feedId: feedDbItem.id)
                        }
                    } else {
                        updateFeedDatabase(feedDbItem: feedDbItem, feedSpec: jsonResult)
                        updateFeedObjects(feedList: jsonResult, feedId: feedDbItem.id)
                        print("Missing key: VERSION")
                        // TODO: Increment error count?
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    
    func refreshObjects() {
        for o in feedObjects {
            let objectFeeds = feeds.filter({ $0.id == o.feedId })
            
            do {
                try realm.write {
                    if objectFeeds.count > 0 {
                        o.deleted = (objectFeeds.first?.deleted)!
                        o.active  = (objectFeeds.first?.active)!
                    } else {
                        o.deleted = true
                        o.active  = false
                    }
                }
            } catch {
                print("Error: \(error)")
            }
            
        }
    }
    
    
    func updateFeeds() {
        print("updateFeeds")
        
        let updateInterval = 10 //randRange(lower: 3, upper: 5)
        refreshObjects()

        for ob in feedObjects {
            print("Object: " + "ID: " + ob.id + " | Active: " + String(ob.active) + " | Deleted: " + String(ob.deleted) )
        }
        
        for fe in feeds {
            // Download if [ "MISSING" || "TIME SINCE LAST UPDATE" > N ]

            let timeSinceUpdate = abs(NSDate().timeIntervalSince1970.distance(to: Double(fe.updatedUtx)))
            let deleted = fe.deleted
            let active = fe.active
            
            print("Time Since Update: " + String(timeSinceUpdate))
            print(String(fe.id) + " " + String(fe.active) + " " + String(fe.lat) + " " + String(fe.lng) + " " + String(fe.url))
            print("FeedObjectCount: " + String(feedObjects.count))
            
            if active && !deleted {
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
    
    
}
