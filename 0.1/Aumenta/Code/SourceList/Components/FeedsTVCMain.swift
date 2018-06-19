//
//  FeedsTVCMain.swift
//  Aumenta
//
//  Created by Tim Sandgren on 2018-06-19.
//  Copyright © 2018 Abstraqata. All rights reserved.
//

import Foundation

extension FeedsTVC {
    
    
    @objc func mainUpdate(){
        
        tableView.reloadData()
        
        if updateTimer.timeInterval != updateInterval {
            updateTimer.invalidate()
        }
        
        if !updateTimer.isValid {
            updateTimer = Timer.scheduledTimer(
                timeInterval: updateInterval,
                target: self, selector: #selector(mainUpdate),
                userInfo: nil, repeats: true)
        }
        
    
    }
    
    
    
}
