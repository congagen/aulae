//
//  AppDelegate.swift
//  ArkitTest
//
//  Created by Tim Sandgren on 2018-05-19.
//  Copyright © 2018 Abstraqata. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window?.tintColor = UIColor.white
        return true
    }

    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print(options.description)
        
        // let sendingAppID = options[.sourceApplication]
        
        let topicString = url.absoluteString.lowercased().replacingOccurrences(of:"aulaeapp://", with: "")
        var urlString = url.absoluteString.lowercased().replacingOccurrences(of:"aulaeapp://", with: "")
        
        if urlString.lowercased().contains("https") {
            print("OK")
        } else {
            if urlString.lowercased().contains("http") {
                urlString = urlString.replacingOccurrences(of: "http", with: "https")
            } else {
                urlString = "https://" + urlString
            }
        }
        
        let alertController = UIAlertController(title: "Add this source?", message: topicString, preferredStyle: .alert)
        
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

