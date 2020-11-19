//
//  FeedsTVCMain.swift
//  aulae
//
//  Created by Tim Sandgren on 2018-06-19.
//  Copyright © 2018 Tim Sandgren. All rights reserved.
//

import Foundation

extension FeedsTVC {
    
    
    @objc func mainUpdate() {
        
        if tableView.isEditing {
            tableView.reloadData()
        }
        
        
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
