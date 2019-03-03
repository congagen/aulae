//
//  NavBar.swift
//  Aumenta
//
//  Created by Tim Sandgren on 2019-03-03.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import UIKit

class NavBar: UINavigationBar {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    override func didMoveToWindow() {
        self.setBackgroundImage(UIImage(), for: .default)
        self.shadowImage = UIImage()
        
        self.backgroundColor = UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 0.3)
        self.isTranslucent = true
    }

}
