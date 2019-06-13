//
//  UIOps.swift
//  Aulae
//
//  Created by Tim Sandgren on 2019-03-12.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import Foundation
import UIKit

class UIOps {
    
    
    func updateNavUiMode(navCtrl: UINavigationController, darkMode: Bool){
        
        if darkMode {
            navCtrl.navigationBar.barStyle       = .blackTranslucent
            navCtrl.navigationBar.tintColor      = .black
            navCtrl.navigationBar.tintColor      = .white
            navCtrl.navigationBar.isTranslucent  = true
        } else {
            navCtrl.navigationBar.barStyle       = .default
            navCtrl.navigationBar.tintColor      = .white
            navCtrl.navigationBar.tintColor      = .black
            navCtrl.navigationBar.isTranslucent  = true
        }
        
    }
    
    
    func initTabUIMode(tabCtrl: UITabBarController, darkMode: Bool){
        
        if darkMode {
            //tabCtrl.tabBar.backgroundColor = .clear
            tabCtrl.tabBar.isTranslucent = true
            tabCtrl.tabBar.barStyle      = .black
            tabCtrl.tabBar.tintColor     = .white
        } else {
            //tabCtrl.tabBar.backgroundColor = .clear
            tabCtrl.tabBar.isTranslucent = true
            tabCtrl.tabBar.barStyle      = .default
            tabCtrl.tabBar.tintColor     = .black
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
