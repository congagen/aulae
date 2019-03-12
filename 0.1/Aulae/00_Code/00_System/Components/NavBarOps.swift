//
//  NavBarOps.swift
//  Aulae
//
//  Created by Tim Sandgren on 2019-03-12.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import Foundation
import UIKit

class NavBarOps {
    
    func showProgress(navCtrl: UINavigationController, progressBar: UIProgressView, view: UIView) {
        
        let navBarHeight = navCtrl.navigationBar.frame.height
        let progressViewFrame = progressBar.frame
        
        let pSetX = progressViewFrame.origin.x
        let pSetY = CGFloat(navBarHeight)
        let pSetWidth = view.frame.width
        let pSetHight = progressViewFrame.height
        
        progressBar.frame = CGRect(x: pSetX, y: pSetY, width: pSetWidth, height: pSetHight)
        navCtrl.navigationBar.addSubview(progressBar)
        progressBar.translatesAutoresizingMaskIntoConstraints = true
        
    }
    
}
