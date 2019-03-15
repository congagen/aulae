//
//  GuideViewController.swift
//  Aulae
//
//  Created by Tim Sandgren on 2019-03-15.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import UIKit

class GuideViewController: UIViewController {

    
    let orientationValue = UIInterfaceOrientation.portrait.rawValue
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIDevice.current.setValue(orientationValue, forKey: "orientation")

        // Do any additional setup after loading the view.
    }
    
    

    

}
