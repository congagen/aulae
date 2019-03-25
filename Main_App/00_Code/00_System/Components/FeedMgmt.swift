//
//  FeedMgmt.swift
//  aulae
//
//  Created by Tim Sandgren on 2018-06-18.
//  Copyright © 2018 Abstraqata. All rights reserved.
//

import Foundation
import CoreLocation
import Realm
import RealmSwift


class FeedMgmt {
    
    lazy var realm = try! Realm()
    lazy var rlmSession: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var rlmFeeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
    
    let validFeedContentObjectKeys = ["name", "id", "type"]
    
    var apiHeaderValue = ""
    var apiHeaderFeild = ""
    
    let httpDl = HttpDownloader()
    
    
    func refreshObjects() {
        print("refreshObjects")
        
        for o in feedObjects {
            let objectFeeds = rlmFeeds.filter({ $0.id == o.feedId})
            
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
    

    func storeFeedObject(objInfo: [String : Any], objFilePath: URL, feedId: String) {
        print("storeFeedObject")
        
        let current = feedObjects.filter( {$0.feedId == feedId && ($0.uuid == objInfo["uuid"] as! String)} )
        let rlmObj = RLM_Obj()
        
        do {
            try realm.write {
                
                for c in current{
                    realm.delete(c)
                }
                
                rlmObj.feedId      = feedId
                rlmObj.contentUrl  = objInfo["url"] as! String
                rlmObj.uuid        = objInfo["uuid"] as! String
                
                rlmObj.instance    = objInfo["instance"] as! Bool

                rlmObj.name        = objInfo["name"] as! String
                rlmObj.info        = objInfo["info"] as! String
                rlmObj.filePath    = objFilePath.absoluteString
            
                rlmObj.contentLink = objInfo["content_link"] as! String
                rlmObj.directLink  = objInfo["direct_link"] as! Bool

                rlmObj.text        = objInfo["text"] as! String
                rlmObj.font        = objInfo["font"] as! String

                rlmObj.world_position = objInfo["world_position"] as! Bool
                rlmObj.billboard   = objInfo["billboard"] as! Bool
                
                rlmObj.world_scale = objInfo["world_scale"] as! Bool
                rlmObj.scale       = objInfo["scale"] as! Double
                
                rlmObj.type        = objInfo["type"] as! String
                rlmObj.style       = objInfo["style"] as! Int
                rlmObj.hex_color   = objInfo["hex_color"] as! String
                
                rlmObj.rotate      = objInfo["rotate"] as! Double
                rlmObj.hoover      = objInfo["hoover"] as! Double
                
                rlmObj.lat         = objInfo["lat"] as! Double
                rlmObj.lng         = objInfo["lng"] as! Double
                rlmObj.alt         = objInfo["alt"] as! Double
                
                rlmObj.x_pos       = objInfo["x_pos"] as! Double
                rlmObj.y_pos       = objInfo["y_pos"] as! Double
                rlmObj.z_pos       = objInfo["z_pos"] as! Double

                rlmObj.radius      = objInfo["radius"] as! Double

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
    
    
    func updateFeedObjects(feedSpec: Dictionary<String, AnyObject>, feedId: String, feedDbItem: RLM_Feed) {
        print("! updateFeedObjects !")
        
        print(feedSpec)
        
        for o in feedObjects.filter( {$0.feedId == feedId} ) {
            do {
                try realm.write {
                    realm.delete(o)
                }
            } catch {
                print("Error: \(error)")
            }
        }
        
        if feedSpec.keys.contains("content") {
            for k in (feedSpec["content"]?.allKeys)! {
                
                let itemSpec = feedSpec["content"]![k] as! Dictionary<String, AnyObject>
                let contentItemIsValid = validateObj(keyList: validFeedContentObjectKeys, dict: itemSpec)
                
                let objUid = UUID().uuidString
                let itemContentType = itemSpec["type"] as! String
                
                if contentItemIsValid {
                    let objData: [String : Any] = [
                        "name":             itemSpec["name"]    as! String,
                        "version":          itemSpec["version"] as! Int,
                        "id":               itemSpec["id"]      as! String,
                        "uuid":             objUid,
                        "feed_id":          feedId,
                        "type":             itemContentType,
                        
                        "billboard":        valueIfPresent(dict: itemSpec, key: "billboard", placeHolderValue: true),

                        "style":            valueIfPresent(dict: itemSpec, key: "style",     placeHolderValue: 1) as! Int,
                        "mode":             valueIfPresent(dict: itemSpec, key: "mode",      placeHolderValue: "free"),
                        "hex_color":        valueIfPresent(dict: itemSpec, key: "hex_color", placeHolderValue: "7122e8"),

                        "url":              valueIfPresent(dict: itemSpec, key: "url",       placeHolderValue: ""),
                        "content_link":     valueIfPresent(dict: itemSpec, key: "content_link", placeHolderValue: ""),
                        "direct_link":      valueIfPresent(dict: itemSpec, key: "direct_link", placeHolderValue: false),
                        
                        "info":             valueIfPresent(dict: itemSpec, key: "info",      placeHolderValue: ""),
                        "text":             valueIfPresent(dict: itemSpec, key: "text",      placeHolderValue: ""),
                        "font":             valueIfPresent(dict: itemSpec, key: "font",      placeHolderValue: "Arial"),

                        "instance":         valueIfPresent(dict: itemSpec, key: "instance",  placeHolderValue: false),

                        "rotate":           valueIfPresent(dict: itemSpec, key: "rotate",    placeHolderValue: 0.0),
                        "hoover":           valueIfPresent(dict: itemSpec, key: "hoover",    placeHolderValue: 0.0),

                        "scale":            valueIfPresent(dict: itemSpec, key: "scale",     placeHolderValue: 1.0),
                        "world_scale":      valueIfPresent(dict: itemSpec, key: "world_scale", placeHolderValue: true),
                        "world_position":   valueIfPresent(dict: itemSpec, key: "world_position", placeHolderValue: true),

                        "lat":              valueIfPresent(dict: itemSpec, key: "lat",       placeHolderValue: 80.0),
                        "lng":              valueIfPresent(dict: itemSpec, key: "lng",       placeHolderValue: 0.0),
                        "alt":              valueIfPresent(dict: itemSpec, key: "alt",       placeHolderValue: 0.0),
                        
                        "x_pos":            valueIfPresent(dict: itemSpec, key: "x_pos",     placeHolderValue: 0.0),
                        "y_pos":            valueIfPresent(dict: itemSpec, key: "y_pos",     placeHolderValue: 0.0),
                        "z_pos":            valueIfPresent(dict: itemSpec, key: "z_pos",     placeHolderValue: 0.0),

                        "radius":           valueIfPresent(dict: itemSpec, key: "radius",    placeHolderValue: 0.0)
                    ]
                    
                    let isInstance:Bool = objData["instance"]! as! Bool
                    
                    if itemContentType != "text" && itemSpec.keys.contains("url") {
                        let contentUrl      = itemSpec["url"] as! String
                        let documentsUrl    = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
                        let fileName        = feedDbItem.id + String(feedDbItem.version) + (URL(string: contentUrl)?.lastPathComponent)!
                        let destinationUrl  = documentsUrl.appendingPathComponent(fileName)

                        storeFeedObject(objInfo: objData, objFilePath: destinationUrl!, feedId: feedId)
                        
                        if let URL = URL(string: contentUrl) {
                            let _ = httpDl.loadFileAsync(
                                removeExisting:  !isInstance,
                                url: URL as URL, destinationUrl: destinationUrl!,
                                completion: {}
                            )
                        }
                       
                    } else {
                        storeFeedObject(objInfo: objData, objFilePath: URL(fileURLWithPath: ""), feedId: feedId)
                    }
                }
            }
        }
    }
    
    
    func updateFeedItem(feedDbItem: RLM_Feed, feedSpec: Dictionary<String, AnyObject>) {
        print("updateFeedDatabase")
        
        let vKeys = ["id", "name", "version", "updated_utx", "content"]
        let valid = validateObj(keyList: vKeys, dict: feedSpec)
        
        if valid {
            //let sID: String       = feedSpec["id"] as! String TODO
            let sID: String       = UUID().uuidString
            let sName: String     = feedSpec["name"] as! String
            let sVersion: Int     = feedSpec["version"] as! Int
            let sUpdated_utx: Int = feedSpec["updated_utx"] as! Int
            
            let sInfo: String = valueIfPresent(dict: feedSpec, key: "info", placeHolderValue: "") as! String
            let thumbUrl: String = valueIfPresent(dict: feedSpec, key: "thumb_url", placeHolderValue: "") as! String
            
            let timeSinceUpdate = abs(NSDate().timeIntervalSince1970.distance(to: Double(feedDbItem.updatedUtx)))
            print(timeSinceUpdate)

            do {
                try realm.write {
                    feedDbItem.id         = sID
                    feedDbItem.name       = sName
                    feedDbItem.info       = sInfo
                    feedDbItem.version    = sVersion
                    feedDbItem.updatedUtx = sUpdated_utx
                    feedDbItem.thumbImageUrl = thumbUrl
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
    
    
    func storeThumb(feedDBItem: RLM_Feed, thumbImageFilePath: URL)  {
        print("storeThumb")
        
        do {
            try realm.write {
                feedDBItem.thumbImagePath = thumbImageFilePath.path
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    
    func downloadThumb(feedDBItem: RLM_Feed, fileName: String) {
        print("downloadThumb")

        let thImgUrl = URL(string: feedDBItem.thumbImageUrl)
        
        let contentUrl      = feedDBItem.thumbImageUrl
        let documentsUrl    = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
        let fileName        = feedDBItem.id + String(feedDBItem.id) + "_" + (URL(string: contentUrl)?.lastPathComponent)!
        let destinationUrl  = documentsUrl.appendingPathComponent(fileName)
        
        let _ = httpDl.loadFileAsync(
            removeExisting: true, url: thImgUrl!, destinationUrl: destinationUrl!,
            completion: { DispatchQueue.main.async { self.storeThumb(feedDBItem: feedDBItem, thumbImageFilePath: destinationUrl!) } }
        )
    }
    
    
    func storeFeed(feedData: Dictionary<String, AnyObject>, feedDbItem: RLM_Feed, checkVersion: Bool) {
        print("storeFeed")
        
        if feedDbItem.thumbImageUrl != "" {
            downloadThumb(feedDBItem: feedDbItem, fileName: "thumb_" + feedDbItem.id)
        }
        
        if feedData.keys.contains("version") {
            if let v: Int = feedData["version"] as? Int {
                if v != feedDbItem.version || !checkVersion {
                    updateFeedItem(feedDbItem: feedDbItem, feedSpec: feedData)
                    updateFeedObjects(feedSpec: feedData, feedId: feedDbItem.id, feedDbItem: feedDbItem)
                }
            } else {
                updateFeedItem(feedDbItem: feedDbItem, feedSpec: feedData)
                updateFeedObjects(feedSpec: feedData, feedId: feedDbItem.id, feedDbItem: feedDbItem)
            }
        } else {
            do {
                try realm.write {
                    feedDbItem.errors += 10
                    feedDbItem.active  = false
                    feedDbItem.name    = "Offline"
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    
    func storeFeedJson(fileUrl: URL, feedDbItem: RLM_Feed) {
        print("storeFeedJson")
        
        if FileManager.default.fileExists(atPath: fileUrl.path) {
            do {
                let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                
                if let jsonResult = jsonResult as? Dictionary<String, AnyObject> {
                    storeFeed(feedData: jsonResult, feedDbItem: feedDbItem, checkVersion: true)
                }
            } catch {
                print(error)
            }
        }
    }
    
    
    @objc func storeFeedApi(result: Dictionary<String, AnyObject>, feedDbItem: RLM_Feed) {
        print("storeFeedApi")
        print(result)
        
        DispatchQueue.main.async {
            self.storeFeed(feedData: result, feedDbItem: feedDbItem, checkVersion: true)
        }
    }
    
    
    func updateFeeds(checkTimeSinceUpdate: Bool) {
        print("updateFeeds")
        print("Feed Count:      "   + String(rlmFeeds.count))
        print("FeedObjectCount: "   + String(feedObjects.count))

        let updateInterval = Int((rlmSession.first?.feedUpdateInterval)!) + 1
        var shouldUpdate = true

        refreshObjects()

        for fe in rlmFeeds {
            print("Updating Feed: " + fe.name)
            print("Feed ID:       " + String(fe.id))
            print("Feed URL:      " + fe.url)
            
            if checkTimeSinceUpdate {
                let timeSinceUpdate = abs(NSDate().timeIntervalSince1970.distance(to: Double(fe.updatedUtx)))
                print("Time Since Update: " + String(timeSinceUpdate))
                shouldUpdate = Int(timeSinceUpdate) > updateInterval
            }
            
            print(String(fe.id) + " "   + String(fe.active) + " " + String(fe.lat) + " " + String(fe.lng) + " " + String(fe.url))
            
            if fe.active && !fe.deleted && shouldUpdate && fe.url != "" {
                let sourceUrl = URL(string: fe.url)
                let sourceExt = sourceUrl?.pathExtension.lowercased()
                
                let fileName = fe.id + ".json"
                let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
                let destinationUrl = documentsUrl.appendingPathComponent(fileName)
                
                if FileManager.default.fileExists(atPath: (destinationUrl?.absoluteString)!) {
                    do{
                        try FileManager.default.removeItem(atPath: (destinationUrl?.absoluteString)! )
                    } catch let error {
                        print("error occurred, here are the details:\n \(error)")
                    }
                }
                
                var sType = "api"
                
                if sourceExt != nil {
                    print("Ext: " + sourceExt!)
                    
                    if sourceExt?.lowercased() == "json" {
                        sType = "json"
                    }
                }
                
                print("sType: " + sType)
                
                if sType == "json" {
                    if let URL = URL(string: fe.url) {
                        print("Downloading Feed JSON: " + fe.url)
                        let _ = httpDl.loadFileAsync(
                            removeExisting: true, url: URL as URL, destinationUrl: destinationUrl!,
                            completion: { DispatchQueue.main.async { self.storeFeedJson(fileUrl: destinationUrl!, feedDbItem: fe) } }
                        )
                    }
                } else {
                    
                    print("Calling Feed API: " + fe.url)
                    NetworkTools().postReq(
                        completion: { r in self.storeFeedApi(result: r, feedDbItem: fe) }, apiHeaderValue: apiHeaderValue,
                        apiHeaderFeild: apiHeaderFeild, apiUrl: fe.url,
                        reqParams: ["lat": String(rlmSession.first!.currentLat), "lng": String(rlmSession.first!.currentLng)]
                    )
                }
                
                do {
                    try realm.write {
                        fe.updatedUtx = Int( Date().timeIntervalSince1970 )
                        
                        if fe.errors > rlmSession.first!.feedErrorThreshold && !fe.deleted {
                            fe.active = false
                        }
                    }
                } catch {
                    print("Error: \(error)")
                }
                
            }
        }
    }
    
    

    
}
