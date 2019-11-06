//
//  AppDelegate.swift
//  ArkitTest
//
//  Created by Tim Sandgren on 2018-05-19.
//  Copyright © 2018 Abstraqata. All rights reserved.
//

import UIKit
import Realm
import RealmSwift


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    
    func migrateRealm(){
        let realmConfUrl = Realm.Configuration.defaultConfiguration.fileURL!
        var currentVersion: UInt64 = 0
        
        do {
            currentVersion = try schemaVersionAtURL(realmConfUrl)
            
            let config = Realm.Configuration(
                schemaVersion: currentVersion + 1
            )
            
            Realm.Configuration.defaultConfiguration = config
            
            // let r = try Realm(configuration: config)
        } catch {
            print(error)
        }
    }
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        do {
            try Realm().objects(RLM_Feed.self)
            try Realm().objects(RLM_Obj.self)
            try Realm().objects(RLM_Session_117.self)
            try Realm().objects(RLM_SysSettings_117.self)
        } catch {
            print("Can't access realm, migration needed")
            migrateRealm()
        }
        
        // TODO: Fix
        let keyWindow = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first

        keyWindow?.tintColor = UIColor.black

        return true
    }

    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        print(options.description)
        
        // let sendingAppID = options[.sourceApplication]

        let topicString = url.absoluteString.lowercased().replacingOccurrences(of: "aulaeapp://", with: "")
        var urlString   = url.absoluteString.lowercased().replacingOccurrences(of: "aulaeapp://", with: "")
        let msgString   = url.absoluteString.lowercased().replacingOccurrences(of: "aulaeapp://", with: "")
        
        if urlString.lowercased().contains("https") {
            print("OK")
        } else {
            if urlString.lowercased().contains("http") {
                urlString = urlString.replacingOccurrences(of: "http", with: "https")
            } else {
                urlString = "https://" + urlString
            }
        }
        
        let alertController = UIAlertController(title: "Add to library?", message: "Value: " + msgString, preferredStyle: .alert)
        
        let urlAction    = UIAlertAction(
            title: "URL", style: UIAlertAction.Style.default,
            handler: {_ in FeedActions().addNewSource(feedUrl: urlString, feedApiKwd: "", refreshExisting: true) } )
        
        let topicAction  = UIAlertAction(
            title: "Topic", style: UIAlertAction.Style.default,
            handler: {_ in FeedActions().addNewSource(
                feedUrl: "https://2hni7twyhl.execute-api.us-east-1.amazonaws.com/dev/test",
                feedApiKwd: topicString,
                refreshExisting: true)
            }
        )
        
        let cancelAction = UIAlertAction(
            title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil
        )
        
        alertController.addAction(urlAction)
        alertController.addAction(topicAction)
        alertController.addAction(cancelAction)
        alertController.view.tintColor = UIColor.black
        
        let keyWindow = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first
        
        let aView = keyWindow?.rootViewController?.view
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = aView
            popoverController.sourceRect = CGRect(x: aView!.bounds.midX, y: aView!.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        window?.rootViewController?.present(alertController, animated: true, completion: nil )
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared refeeds, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

