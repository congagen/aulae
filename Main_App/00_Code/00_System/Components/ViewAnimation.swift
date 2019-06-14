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
    
    
    func hideCompletion(viewToHide: UIView) {
        viewToHide.isHidden = true
    }
    
    
    func resetOpacity(v: UIView, hideView: Bool) {
        v.isHidden = hideView
        
        if v.isHidden {
            v.layer.opacity = 1
        }
    }
    
    
    func fade(viewToAnimate: UIView, aDuration: Double, hideView: Bool, aMode: UIView.AnimationOptions) {
        
        if !hideView && viewToAnimate.isHidden {
            viewToAnimate.layer.opacity = 0
            viewToAnimate.isHidden = false
        }
        
        // let startVal = viewToAnimate.layer.opacity
        
        UIView.transition(with: viewToAnimate,
                          duration: aDuration,
                          options: aMode,
                          animations: { viewToAnimate.layer.opacity = Float(hideView ? 0 : 1)},
                          completion: { _ in self.resetOpacity(v: viewToAnimate, hideView: hideView) }
        )
        

        
    }
    
    
}

