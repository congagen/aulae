//
//  UIOps.swift
//  Aulae
//
//  Created by Tim Sandgren on 2019-03-12.
//  Copyright © 2019 Tim Sandgren. All rights reserved.
//

import UIKit
import Foundation

import Realm
import RealmSwift


class UIOps {
    
    lazy var realm = try! Realm()
    lazy var rlmSystem:  Results<RLM_SysSettings_117> = { self.realm.objects(RLM_SysSettings_117.self) }()
    lazy var rlmSession: Results<RLM_Session_117> = { self.realm.objects(RLM_Session_117.self) }()
    lazy var rlmChatSession: Results<RLM_ChatSess> = { self.realm.objects(RLM_ChatSess.self) }()
    
    let lightTintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.9)
    let darkTintColor = UIColor.darkText
    
    func updateGlobalTint(window: UIWindow) {

        if rlmSystem.first?.uiMode == 1 {
            window.tintColor = UIColor.white
        } else {
            window.tintColor = UIColor.black
        }
  
    }

    
    func updateNavUiMode(navCtrl: UINavigationController){
        // print("Dark Mode Nav: " + String(rlmSystem.first?.uiMode == 1))
        
        if rlmSystem.first?.uiMode == 1 {
            navCtrl.navigationBar.barStyle      = .black
            navCtrl.navigationBar.isTranslucent = true
            navCtrl.navigationBar.tintColor     = lightTintColor
        } else {
            navCtrl.navigationBar.barStyle      = .default
            navCtrl.navigationBar.isTranslucent = true
            navCtrl.navigationBar.tintColor     = darkTintColor
        }
        
    }
    

    func updateTabUIMode(tabCtrl: UITabBarController){
        // print("Dark Mode Tab: " + String(rlmSystem.first?.uiMode == 1))
        
        
        if rlmSystem.first?.uiMode == 1 {
            tabCtrl.tabBar.isTranslucent = true
            tabCtrl.tabBar.barStyle      = .black
            tabCtrl.tabBar.tintColor     = lightTintColor
        } else {
            tabCtrl.tabBar.isTranslucent = true
            tabCtrl.tabBar.barStyle      = .default
            tabCtrl.tabBar.tintColor     = darkTintColor
        }
        
    }
    
    
    func showLogo(navCtrl: UINavigationController, imageName: String) {
        let logo = UIImage(named: imageName)
        let imageView = UIImageView(image: logo)
        
        imageView.contentMode = .scaleAspectFit
        navCtrl.navigationBar.topItem?.titleView = imageView
    }
    
    
    func showProgressBar(navCtrl: UINavigationController, progressBar: UIProgressView, view: UIView, timeoutPeriod: Double) {
        
        let navBarHeight = navCtrl.navigationBar.frame.height
        let progressViewFrame = progressBar.frame
        
        progressBar.tintColor = UIColor(displayP3Red: 0.5, green: 1, blue: 0.7, alpha: 1)
        
        progressBar.setProgress(0, animated: false)
        progressBar.layoutIfNeeded()
        progressBar.layer.removeAllAnimations()
        
        let pSetX = progressViewFrame.origin.x
        let pSetY = CGFloat(navBarHeight)
        let pSetWidth = view.frame.width
        let pSetHight = progressViewFrame.height
        
        progressBar.frame = CGRect(x: pSetX, y: pSetY, width: pSetWidth, height: pSetHight)
        navCtrl.navigationBar.addSubview(progressBar)
        progressBar.translatesAutoresizingMaskIntoConstraints = true
        
        progressBar.setProgress(Float(timeoutPeriod), animated: true)
        
        if timeoutPeriod != 0 {
            Timer.scheduledTimer(withTimeInterval: timeoutPeriod, repeats: false, block: {_ in progressBar.removeFromSuperview()})
        }

    }
    
}
