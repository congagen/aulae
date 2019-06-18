//
//  ViewAnimation.swift
//  Aulae
//
//  Created by Tim Sandgren on 2019-05-01.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import UIKit
import Foundation

class ViewAnimation {
    
    func horizontalScroll(viewToAnimate: UIView, viewToMeasure: UIView, aDuration: Double, hideView: Bool, aMode: UIView.AnimationOptions) {
        if !hideView {
            
            UIView.transition(with: viewToAnimate,
                              duration: aDuration,
                              options: aMode,
                              animations: { viewToAnimate.center.y = viewToMeasure.frame.height * 0.5 },
                              completion: nil)
        } else {
            UIView.transition(with: viewToAnimate,
                              duration: aDuration,
                              options: aMode,
                              animations: { viewToAnimate.center.y = -viewToMeasure.frame.height},
                              completion: nil)
        }
    }
    
    
    func morphText(objToAnimate: UIButton, aDuration: Double, newText: String, aMode: UIView.AnimationOptions) {
        UIView.transition(with: objToAnimate,
                          duration: aDuration,
                          options: aMode,
                          animations: { objToAnimate.titleLabel?.text = newText},
                          completion: nil)
    }
    
    
    func resetOpacity(v: UIView, hideView: Bool) {
        v.isHidden = false
        
        if hideView {
            v.layer.opacity = 0
        }
    }
    
    
    func fade(viewToAnimate: UIView, aDuration: Double, hideView: Bool, aMode: UIView.AnimationOptions) {
        
        if !hideView {
            viewToAnimate.isHidden = false
        }
        
        UIView.transition(
            with: viewToAnimate,
            duration: aDuration,
            options: .curveEaseInOut,
            animations: { viewToAnimate.layer.opacity = Float(hideView ? 0 : 1) },
            completion: nil
        )
        
    }
    
    
}

