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
        print("storeFeedObject")
        
        let rlmObj = RLM_Obj()
        
        do {
            try realm.write {
                rlmObj.id       = objInfo["id"] as! String
                rlmObj.feedId   = originFeed

                rlmObj.name     = objInfo["name"] as! String
                rlmObj.info     = objInfo["info"] as! String
                rlmObj.filePath = objFilePath.absoluteString
                rlmObj.world_position = objInfo["world_position"] as! Bool
                rlmObj.world_scale = objInfo["world_scale"] as! Bool

                rlmObj.type     = objInfo["type"] as! String
                rlmObj.style    = objInfo["style"] as! Int
                rlmObj.text     = objInfo["text"] as! String
                rlmObj.hex_color = objInfo["hex_color"] as! String
                
                rlmObj.lat      = objInfo["lat"] as! Double
                rlmObj.lng      = objInfo["lng"] as! Double
                rlmObj.alt      = objInfo["alt"] as! Double
                
                rlmObj.x_pos    = objInfo["x_pos"] as! Double
                rlmObj.y_pos    = objInfo["y_pos"] as! Double
                rlmObj.z_pos    = objInfo["y_pos"] as! Double

                rlmObj.scale = objInfo["scale"] as! Double
                
                realm.add(rlmObj)
            }
        } catch {
            print("Error: \(error)")
        }
    }

    
    func validateObj(keyList: [String], dict: Dictionary<String, AnyObject>) -> Bool {
        print("validateObj")

        var valid = true
        
        for k in keyList {
            if dict.keys.contains(k) == false {
                valid = false
            } else {
                print("Valid: " + valid.description)
            }
        }
        
        return valid
        
    }
    
    
    func valueIfPresent(dict: Dictionary<String, AnyObject>, key: String, placeHolderValue: Any) -> Any {
        
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
            let valid = validateObj(keyList: validObjectJsonKeys, dict: feedContent)
            
            // updated_utx
            if valid {
                
                let objData: [String : Any] = [
                    "name":             feedContent["name"] as! String,
                    "id":               feedContent["id"]   as! String,
                    "feed_id":          feedId,

                    "version":          feedContent["version"] as! Int,
                    
                    "type":             feedContent["type"]  as! String,
                    "style":            valueIfPresent(dict: feedContent, key: "style", placeHolderValue:  1) as! Int,
                    "mode":             valueIfPresent(dict: feedContent, key: "mode", placeHolderValue:   "free"),
                    "hex_color":        valueIfPresent(dict: feedContent, key: "hex_color", placeHolderValue:   "7259ff"),

                    "url":              valueIfPresent(dict: feedContent, key: "url",    placeHolderValue: ""),

                    "info":             valueIfPresent(dict: feedContent, key: "info",   placeHolderValue: ""),
                    "text":             valueIfPresent(dict: feedContent, key: "text",   placeHolderValue: ""),
                    
                    "world_position": valueIfPresent(dict: feedContent, key: "world_position", placeHolderValue: true),
                    "world_scale":    valueIfPresent(dict: feedContent, key: "world_scale", placeHolderValue: true),
                    
                    "lat":              valueIfPresent(dict: feedContent, key: "lat",    placeHolderValue: 0.0),
                    "lng":              valueIfPresent(dict: feedContent, key: "lng",    placeHolderValue: 0.0),
                    "alt":              valueIfPresent(dict: feedContent, key: "alt",    placeHolderValue: 0.0),
                    
                    "x_pos":            valueIfPresent(dict: feedContent, key: "x_pos",  placeHolderValue: 0.0),
                    "y_pos":            valueIfPresent(dict: feedContent, key: "y_pos",  placeHolderValue: 0.0),
                    "z_pos":            valueIfPresent(dict: feedContent, key: "z_pos",  placeHolderValue: 0.0),

                    "radius":           valueIfPresent(dict: feedContent, key: "radius", placeHolderValue: 1.0),
                    "scale":            valueIfPresent(dict: feedContent, key: "scale",  placeHolderValue: 1.0)
                ]
                
                if feedContent.keys.contains("url") {
                    let contentUrl = feedContent["url"] as! String
                    let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
                    let fileName = (URL(string: contentUrl)?.lastPathComponent)!
                    let destinationUrl = documentsUrl.appendingPathComponent(fileName)
                    
                    if let URL = URL(string: contentUrl) {
                        let _ = httpDl.loadFileAsync(
                            url: URL as URL, destinationUrl: destinationUrl!,
                            completion: { DispatchQueue.main.async {
                                self.storeFeedObject(objInfo: objData, objFilePath: destinationUrl!, originFeed: feedId )} })
                    }
                } else {
                    let placeholderUrl = URL(fileURLWithPath: "")
                    storeFeedObject(objInfo: objData, objFilePath: placeholderUrl, originFeed: feedId)
                }
            } else {
                print("ERROR: MALFORMED FEED ITEM: ")
                print((feedContent))
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
            
            let timeSinceUpdate = abs(NSDate().timeIntervalSince1970.distance(to: Double(feedDbItem.updatedUtx)))
            print(timeSinceUpdate)

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
            do {
                try realm.write {
                    feedDbItem.errors += 1
                }
            } catch {
                print("Error: \(error)")
            }
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
                        feedDbItem.errors += 1
                        updateFeedDatabase(feedDbItem: feedDbItem, feedSpec: jsonResult)
                        updateFeedObjects(feedList: jsonResult, feedId: feedDbItem.id)
                        
                        print("Error: updateFeed: Missing version key")
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
        
        let updateInterval = Int((session.first?.feedUpdateInterval)!) + 1
        refreshObjects()

        for ob in feedObjects {
            print("Object: " + "Path: " + ob.filePath + " | Active: " + String(ob.active) + " | Deleted: " + String(ob.deleted) )
        }
        
        for fe in feeds {
            // Download if [ "MISSING" || "TIME SINCE LAST UPDATE" > N ]
            // TODO IF ERRCOUNT > THRESH -> Disable

            let timeSinceUpdate = abs(NSDate().timeIntervalSince1970.distance(to: Double(fe.updatedUtx)))
            
            do {
                try realm.write {
                    if fe.errors > session.first!.feedErrorThreshold && !fe.deleted {
                        fe.active = false
                    }
                }
            } catch {
                print("Error: \(error)")
            }
            
            print("Time Since Update: " + String(timeSinceUpdate))
            print(String(fe.id) + " " + String(fe.active) + " " + String(fe.lat) + " " + String(fe.lng) + " " + String(fe.url))
            print("FeedObjectCount: " + String(feedObjects.count))
            
            if fe.active && !fe.deleted {
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
    
    
    func refreshObjects() {
        print("refreshObjects")
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
    
}
