//
//  FeedMgmt.swift
//  aulae
//
//  Created by Tim Sandgren on 2018-06-18.
//  Copyright © 2018 Tim Sandgren. All rights reserved.
//

import Foundation
import CoreLocation
import Realm
import RealmSwift


class FeedMgmt {
    
    lazy var realm = try! Realm()
    lazy var rlmSession: Results<RLM_Session_117>    = { self.realm.objects(RLM_Session_117.self) }()
    lazy var rlmSystem: Results<RLM_SysSettings_117> = { self.realm.objects(RLM_SysSettings_117.self) }()
    lazy var errorLog: Results<RLM_Errors> = { self.realm.objects(RLM_Errors.self) }()

    lazy var rlmFeeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
    
    let validFeedContentObjectKeys = ["name", "type"]
    
    var libMgmtVC: FeedsTVC? = nil
    
    var apiHeaderValue = ""
    var apiHeaderFeild = ""
    
    let httpDl = HttpDownloader()
    
    
    func objectIsOfType<T>(object: Any, dummyValOfThatType: T) -> Bool {
        let rslt: Bool = object is T
        return rslt
    }
    
    
    func refreshObjects() {
        print("refreshObjects")
        
        for o in feedObjects {
            let objectSources = rlmFeeds.filter({$0.id == o.feedId})
            
            do {
                try realm.write {
                    if objectSources.count > 0 {
                        o.deleted = (objectSources.first?.deleted)!
                        o.active  = (objectSources.first?.active)!
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
    

    func storeFeedObject(objInfo: [String : Any], objFilePath: URL, feedId: String) throws {
        print("storeFeedObject")
                
        //TODO: Store and append custom marker filepath
        
        let objFeed = rlmFeeds.filter({$0.id == feedId})
        
        // Store Custom Markers
        var prvCmarkerUrl = ""
        var prvCmarkerPth = ""
        
        if objFeed.count > 0 {
            if objFeed.first?.customMarkerUrl  != "" {prvCmarkerUrl = objFeed.first!.customMarkerUrl}
            if objFeed.first?.customMarkerPath != "" {prvCmarkerPth = objFeed.first!.customMarkerPath}
        }
        
        let currentFeedObjs = feedObjects.filter( {$0.feedId == feedId && ($0.uuid == objInfo["uuid"] as! String)} )
                
        for c in currentFeedObjs{
            do {
                try realm.write {
                    realm.delete(c)
                }
            } catch {
                print("Error: \(error)")
            }
        }
        
        let rlmObj = RLM_Obj()
    
        
        do {
            try realm.write {
                rlmObj.feedId       = feedId
                rlmObj.uuid         = objInfo["uuid"] as! String
                rlmObj.instance     = objInfo["instance"] as! Bool

                rlmObj.name         = objInfo["name"] as! String
                rlmObj.info         = objInfo["info"] as! String
                
                if prvCmarkerPth != "" {
                    rlmObj.filePath = prvCmarkerPth
                } else {
                    rlmObj.filePath = objFilePath.absoluteString
                }
            
                rlmObj.contentUrl  = objInfo["url"] as! String
                rlmObj.contentLink = (objInfo["content_link"] as! String)
                rlmObj.chatUrl     = objInfo["chat_url"] as! String
                rlmObj.directLink  = objInfo["direct_link"] as! Bool
                
                rlmObj.customMarkerUrl = prvCmarkerUrl
                rlmObj.customMarkerPath = prvCmarkerPth

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
                
                rlmObj.localOrient = objInfo["local_orientation"] as! Bool
                
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
    
    
    func valueIfPresent(valDict: Dictionary<String, AnyObject>, dctKey: String, placeHolderValue: Any) -> Any {
        print("-> valueIfPresent!")
        print(dctKey)
        print(placeHolderValue)
        
        if valDict.keys.contains(dctKey) {
            print(valDict[dctKey]!)
            
            if valDict[dctKey] != nil {
                if objectIsOfType(object: valDict[dctKey]!, dummyValOfThatType: placeHolderValue) {
                     return valDict[dctKey]!
                } else {
                    return placeHolderValue
                }
            } else {
                return placeHolderValue
            }
            
        } else {
            print("Missing")
            return placeHolderValue
        }
        
    }
    
    
    func updateFeedObjects(feedData: Dictionary<String, AnyObject>, feedId: String, feedDbItem: RLM_Feed) {
        print("! updateFeedObjects !")
        
        var deleteExisting = true
        
        if feedData.keys.contains("version") {
            deleteExisting = Int(feedDbItem.version) != feedData["version"]! as! Int
        }
        
        let prevFeedUid        = feedId + "OLD"
        let currentFeedObjects = feedObjects.filter( {$0.feedId == feedId})
        
        for o in currentFeedObjects {
            print(o.isInvalidated)
            do {
                try realm.write {
                    o.uuid = prevFeedUid
                }
            } catch {
                print("Error: \(error)")
            }
        }
        
        if feedData.keys.contains("content") {
            for k in (feedData["content"]?.allKeys)! {
                
                let itemSpec = feedData["content"]![k] as! Dictionary<String, AnyObject>
                
                let objUid = UUID().uuidString
                let itemContentType = itemSpec["type"] as! String
                var remoteContentUrl = valueIfPresent(valDict: itemSpec, dctKey: "url", placeHolderValue: "")
                
                if feedDbItem.customMarkerUrl != "" {
                    remoteContentUrl = feedDbItem.customMarkerUrl
                    print("!! feedDbItem.customMarkerUrl !!")
                }
                
                let objData: [String : Any] = [
                    "name":              valueIfPresent(valDict: itemSpec, dctKey: "name",      placeHolderValue: String(feedObjects.count)),
                    "id":                valueIfPresent(valDict: itemSpec, dctKey: "id",        placeHolderValue: objUid),
                    "version":           valueIfPresent(valDict: itemSpec, dctKey: "version",   placeHolderValue: 1),
                    "info":              valueIfPresent(valDict: itemSpec, dctKey: "info",      placeHolderValue: ""),

                    "uuid":              objUid,
                    "feed_id":           feedId,
                    
                    "type":              itemContentType,
                    "url":               remoteContentUrl,

                    "billboard":         valueIfPresent(valDict: itemSpec, dctKey: "billboard", placeHolderValue: true),

                    "style":             valueIfPresent(valDict: itemSpec, dctKey: "style",     placeHolderValue: 1) as! Int,
                    "mode":              valueIfPresent(valDict: itemSpec, dctKey: "mode",      placeHolderValue: "free"),
                    "hex_color":         valueIfPresent(valDict: itemSpec, dctKey: "hex_color", placeHolderValue: "7122e8"),

                    "content_link":      valueIfPresent(valDict: itemSpec, dctKey: "content_link", placeHolderValue: ""),
                    "direct_link":       valueIfPresent(valDict: itemSpec, dctKey: "direct_link", placeHolderValue: false),
                    "chat_url":          valueIfPresent(valDict: itemSpec, dctKey: "chat_url",  placeHolderValue: ""),

                    "text":              valueIfPresent(valDict: itemSpec, dctKey: "text",      placeHolderValue: ""),
                    "font":              valueIfPresent(valDict: itemSpec, dctKey: "font",      placeHolderValue: ""),
                    "instance":          valueIfPresent(valDict: itemSpec, dctKey: "instance",  placeHolderValue: true),

                    "rotate":            valueIfPresent(valDict: itemSpec, dctKey: "rotate",    placeHolderValue: 0.0),
                    "hoover":            valueIfPresent(valDict: itemSpec, dctKey: "hoover",    placeHolderValue: 0.0),

                    "scale":             valueIfPresent(valDict: itemSpec, dctKey: "scale",     placeHolderValue: 1.0),
                    "world_scale":       valueIfPresent(valDict: itemSpec, dctKey: "world_scale", placeHolderValue: true),
                    "local_orientation": valueIfPresent(valDict: itemSpec, dctKey: "local_orientation", placeHolderValue: false),

                    "world_position":    valueIfPresent(valDict: itemSpec, dctKey: "world_position", placeHolderValue: true),
                    "lat":               valueIfPresent(valDict: itemSpec, dctKey: "lat",       placeHolderValue: rlmSession.first!.currentLat),
                    "lng":               valueIfPresent(valDict: itemSpec, dctKey: "lng",       placeHolderValue: rlmSession.first!.currentLng),
                    "alt":               valueIfPresent(valDict: itemSpec, dctKey: "alt",       placeHolderValue: 0.0),
                    
                    "x_pos":             valueIfPresent(valDict: itemSpec, dctKey: "x_pos",     placeHolderValue: 0.0),
                    "y_pos":             valueIfPresent(valDict: itemSpec, dctKey: "y_pos",     placeHolderValue: 0.0),
                    "z_pos":             valueIfPresent(valDict: itemSpec, dctKey: "z_pos",     placeHolderValue: 0.0),

                    "radius":            valueIfPresent(valDict: itemSpec, dctKey: "radius",    placeHolderValue: 0.0)
                ]
                    
                //let isInstance: Bool = objData["instance"]! as! Bool
                
                // Download content if present
                if itemContentType != "text" && itemSpec.keys.contains("url") {
                    print("OK!!==!!")
                    print(itemContentType)
                    print(feedDbItem.customMarkerPath)
                    
                    let documentsUrl    = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
                    let fileName        = feedDbItem.id + String(feedDbItem.version) + (URL(string: remoteContentUrl as! String)?.lastPathComponent)!
                    let destinationUrl  = documentsUrl.appendingPathComponent(fileName)
        
                    // ----------------------------------------------------------------------------------------------
                    // storeFeedObject(objInfo: objData, objFilePath: destinationUrl!, feedId: feedId)
                        
                    do {
                        try storeFeedObject(objInfo: objData, objFilePath: destinationUrl!, feedId: feedId)
                    } catch {
                        do {
                            try realm.write {
                                for f in rlmFeeds {
                                    f.active = false
                                }
                            }
                        } catch {
                            print("Error: \(error)")
                        }
                        print("Error: \(error)")
                    }
                    
                    // -----------------------------------------------------------------------------------------------
                    
                    if !FileManager.default.fileExists(atPath: destinationUrl!.path) || deleteExisting {
                        if let cUrl = URL(string: remoteContentUrl as! String) {
                            let _ = httpDl.loadFileAsync(
                                preserveFields: [:],
                                removeExisting: deleteExisting, url: cUrl as URL,
                                destinationUrl: destinationUrl!, completion: {}
                            )
                        }
                    }
                } else {
                                    
                    do {
                        try storeFeedObject(objInfo: objData, objFilePath: URL(fileURLWithPath: ""), feedId: feedId)
                    } catch {
                        do {
                            try realm.write {
                                for f in rlmFeeds {
                                    f.active = false
                                }
                            }
                        } catch {
                            print("Error: \(error)")
                        }
                        print("Error: \(error)")
                    }
                    
                    removeOld(oldId: prevFeedUid)
                }
            }
        }
        
        //Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: {_ in self.removeOld(oldId: prevFeedUid) })
        removeOld(oldId: prevFeedUid)
    }
    
    
    func removeOld(oldId: String)  {
        for o in feedObjects.filter( {$0.uuid == oldId} ) {
            do {
                try realm.write {
                    o.deleted = true
                    realm.delete(o)
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    
    func updateFeedData(feedDbItem: RLM_Feed, feedSpec: Dictionary<String, AnyObject>) {
        print("updateFeedDatabase")
        
        let vKeys = ["name", "version", "updated_utx", "content"]
        let valid = validateObj(keyList: vKeys, dict: feedSpec)
        
        if valid {
            let sID: String       = UUID().uuidString
            let sName: String     = feedSpec["name"] as! String
            let sVersion: Int     = feedSpec["version"] as! Int
            let sUpdated_utx: Int = feedSpec["updated_utx"] as! Int
            
            let sInfo: String = valueIfPresent(valDict: feedSpec, dctKey: "info", placeHolderValue: "") as! String
            let thumbUrl: String = valueIfPresent(valDict: feedSpec, dctKey: "thumb_url", placeHolderValue: feedDbItem.customMarkerUrl) as! String
            
            let timeSinceUpdate = abs(NSDate().timeIntervalSince1970.distance(to: Double(feedDbItem.updatedUtx)))
            print(timeSinceUpdate)

            do {
                try realm.write {
                    if feedDbItem.id == "" || rlmFeeds.filter({$0.id == feedDbItem.id}).count > 1 {
                        feedDbItem.id = sID
                    }
                    feedDbItem.name          = sName
                    feedDbItem.info          = sInfo
                    feedDbItem.version       = sVersion
                    feedDbItem.updatedUtx    = sUpdated_utx
                    feedDbItem.thumbImageUrl = thumbUrl
                    
                    feedDbItem.customMarkerUrl = ""
                    feedDbItem.customMarkerPath = ""
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
            print(feedSpec)
            print("Feed Validation Error: " + String(feedDbItem.sourceUrl))
            
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
        
        let thumbUrl        = feedDBItem.thumbImageUrl
        let documentsUrl    = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
        let fileName        = feedDBItem.id + String(feedDBItem.id) + "_" + (URL(string: thumbUrl)?.lastPathComponent)!
        let destinationUrl  = documentsUrl.appendingPathComponent(fileName)
        
        let _ = httpDl.loadFileAsync(
            preserveFields: [:],
            removeExisting: true, url: thImgUrl!, destinationUrl: destinationUrl!,
            completion: {
                DispatchQueue.main.async {
                    self.storeThumb(feedDBItem: feedDBItem, thumbImageFilePath: destinationUrl!)
                }
            }
        )
    }
    
    
    func validateFeedFields(feedData: Dictionary<String, AnyObject>) -> Bool{
        print("Validating Feed:")
        print(feedData)
        
        if feedData.keys.contains("name") {
            print(feedData["name"]!)
            if !(objectIsOfType(object: feedData["name"]!, dummyValOfThatType: "")) {
                return false
            }
        }
        
        // TODO: Fix Asciimon Go Demo(?)
        if feedData.keys.contains("id") {
            print(feedData["id"]!)
//            if !(objectIsOfType(object: feedData["id"]!, dummyValOfThatType: "")){
//                return false
//            }
        }
        
        if feedData.keys.contains("info") {
            print(feedData["info"]!)
            if !(objectIsOfType(object: feedData["info"]!, dummyValOfThatType: "")){
                return false
            }
        }
        
        if feedData.keys.contains("version") {
            print(feedData["version"]!)
            if !(objectIsOfType(object: feedData["version"]!, dummyValOfThatType: 1)){
                return false
            }
        }
        
        return true
    }
    
    
    func storeFeed(feedData: Dictionary<String, AnyObject>, feedDbItem: RLM_Feed, checkVersion: Bool) throws {
        print("storeFeed")
        
        if validateFeedFields(feedData: feedData) == true {
            // TODO: !! Stresstest !!
            // BUG? (Found nil -> "version")
            if feedData["version"] != nil {
                if (feedData["version"] as! Int) != feedDbItem.version {
                    if feedDbItem.thumbImageUrl != "" {
                        downloadThumb(feedDBItem: feedDbItem, fileName: "thumb_" + feedDbItem.id)
                    }

                    updateFeedData(feedDbItem: feedDbItem, feedSpec: feedData)
                    updateFeedObjects(feedData: feedData, feedId: feedDbItem.id, feedDbItem: feedDbItem)

                    if !feedData.keys.contains("version") {
                        do {
                            try realm.write {
                                feedDbItem.errors += 10
                                feedDbItem.active  = false
                            }
                        } catch {
                            print("Error: \(error)")
                        }
                    }
                }
            }
            
        } else {
            // TODO: Deactivate Feed
            do {
                try realm.write {
                    feedDbItem.active = false
                }
            } catch {
                print("Error: \(error)")
            }
        }
     
        // TODO: !! Stresstest !!
        
    }
    
    
    func storeFeedJson(fileUrl: URL, feedDbItem: RLM_Feed) {
        print("storeFeedJson")
        
        if FileManager.default.fileExists(atPath: fileUrl.path) {
            do {
                let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                
                if let jsonResult = jsonResult as? Dictionary<String, AnyObject> {
                    
                    do {
                        if validateFeedFields(feedData: jsonResult) {
                            try storeFeed(feedData: jsonResult, feedDbItem: feedDbItem, checkVersion: true)
                        } else {
                            do {
                                try realm.write {
                                    feedDbItem.active = false
                                }
                            } catch {
                                print("Error: \(error)")
                            }
                        }
                    } catch {
                        print("Error: \(error)")
                    }
                                    
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
                        
            do {
                if self.validateFeedFields(feedData: result) {
                    try self.storeFeed(feedData: result, feedDbItem: feedDbItem, checkVersion: true)
                } else {
                    do {
                        try self.realm.write {
                            feedDbItem.active = false
                        }
                    } catch {
                        print("Error: \(error)")
                    }
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    
    func manageSourceUpdate(originalFeedInfo: String, sType: String, feedData: RLM_Feed, destinationUrl: URL) {
        if sType == "json" {
            if let URL = URL(string: feedData.sourceUrl) {
                print("Downloading Feed JSON: " + feedData.sourceUrl)
                let _ = httpDl.loadFileAsync(
                    preserveFields: ["customMarkerUrl": feedData.customMarkerUrl, "customMarkerPath": feedData.customMarkerPath],
                    removeExisting: true, url: URL as URL, destinationUrl: destinationUrl,
                    completion: { DispatchQueue.main.async { self.storeFeedJson(fileUrl: destinationUrl, feedDbItem: feedData) } }
                )
            }
        } else {
            print("Calling Feed API: " + feedData.sourceUrl)
            
            NetworkTools().postReq(
                completion: { r in self.storeFeedApi(result: r, feedDbItem: feedData) }, apiHeaderValue: apiHeaderValue,
                apiHeaderFeild: apiHeaderFeild, apiUrl: feedData.sourceUrl,
                reqParams: [
                    "lat": rlmSystem.first!.locationSharing ? String(rlmSession.first!.currentLat) : "",
                    "lng": rlmSystem.first!.locationSharing ? String(rlmSession.first!.currentLng) : "",
                    "kwd": String(feedData.topicKwd),
                    "sid": (rlmSession.first?.sessionUUID)!
                ]
            )
        }
        
        do {
            try realm.write {
                feedData.info = originalFeedInfo
                feedData.updatedUtx = Int( Date().timeIntervalSince1970 )
                if feedData.errors > rlmSystem.first!.feedErrorThreshold && !feedData.deleted {
                    feedData.active = false
                }
            }
        } catch {
            print("Error: \(error)")
        }
        
    }
    
    
    func updateFeeds(checkTimeSinceUpdate: Bool) {
        print("updateFeeds")
        print("Feed Count:      "   + String(rlmFeeds.count))
        print("FeedObjectCount: "   + String(feedObjects.count))
        
        var needsViewRefresh = false
        let updateInterval = Int((rlmSystem.first?.feedUpdateInterval)!) + 1
        var shouldUpdate = true

        refreshObjects()

        for fe in rlmFeeds {
            let feedInfo = fe.info
            
//            var customMarkerPath = fe.customMarkerPath
//            var customMarkerUrl = fe.customMarkerUrl
//            
//            if customMarkerPath != "" {
//                
//            }

            print("Updating Feed: "  + fe.name)
            print("Feed ID:       "  + String(fe.id))
            print("Feed URL:      "  + fe.sourceUrl)
        
            if checkTimeSinceUpdate {
                let timeSinceUpdate = abs(NSDate().timeIntervalSince1970.distance(to: Double(fe.updatedUtx)))
                print("Time Since Update: " + String(timeSinceUpdate))
                shouldUpdate = Int(timeSinceUpdate) > updateInterval
            }
        
            // TODO: If not auto update && All feeds objects present -> Skip Update?
        
            print(String(fe.id) + " "   + String(fe.active) + " " + String(fe.lat) + " " + String(fe.lng) + " " + String(fe.sourceUrl))
        
            if fe.active && !fe.deleted && shouldUpdate && fe.sourceUrl != "" {
                let sourceUrl      = URL(string: fe.sourceUrl)
                let feedExt        = sourceUrl?.pathExtension.lowercased()

                let fileName       = fe.id + ".json"
                let documentsUrl   = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
                let destinationUrl = documentsUrl.appendingPathComponent(fileName)
                
                if FileManager.default.fileExists(atPath: (destinationUrl?.absoluteString)!) {
                    do {
                        try FileManager.default.removeItem(atPath: (destinationUrl?.absoluteString)! )
                    } catch let error {
                        print("error occurred, here are the details:\n \(error)")
                    }
                }
                
                var sType = "api"
                if feedExt != nil {
                    print("Ext: " + feedExt!)
                    if feedExt?.lowercased() == "json" {
                        sType = "json"
                    }
                }
                                
                manageSourceUpdate(originalFeedInfo: feedInfo, sType: sType, feedData: fe, destinationUrl: destinationUrl!)
                
                needsViewRefresh = true
            }
        }
        
        do {
            try realm.write {
                rlmSession.first!.shouldRefreshView = needsViewRefresh
            }
        } catch {
            print("Error: \(error)")
        }
    }
    

    

}
