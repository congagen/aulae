//
//  NodeActions.swift
//  aulae
//
//  Created by Tim Sandgren on 2019-03-04.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import Foundation
import ARKit


extension ARViewer {
    

    func sharePhoto() {
        let renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: [:])
        renderer.scene = sceneView.scene
        renderer.pointOfView = sceneView.pointOfView
        let snapShot = renderer.snapshot(atTime: TimeInterval(0), with: CGSize(width: 100, height: 100), antialiasingMode: .none)
        
        let imageToShare = [snapShot]
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook ]
        
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    
    func shareURLAction(url: String) {
        
        let textToShare = [ url ]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        // activityViewController.excludedActivityTypes = [ UIActivityType.airDrop ]
        
        self.present(activityViewController, animated: true, completion: nil)
        
        resetSeletion()
    }
    
    
    func openUrl(scheme: String) {
        if let url = URL(string: scheme) {
            if #available(iOS 10, *) {
                UIApplication.shared.open(url, options: [:],
                                          completionHandler: {
                                            (success) in
                                            print("Open \(scheme): \(success)")
                })
            } else {
                let success = UIApplication.shared.openURL(url)
                print("Open \(scheme): \(success)")
            }
        }
    }
    
    
    func showSeletedNodeActions(objData: RLM_Obj) {
        print("showSeletedNodeActions")
        let selFeeds = rlmFeeds.filter({$0.id == self.selectedNode?.feedId})
        
        if selectedNode != nil {

            let alert =  UIAlertController(
                title:   (selectedNode?.feedId)! + " - " + (selectedNode?.title)!,
                message: nil,
                preferredStyle: UIAlertController.Style.actionSheet
            )
            
            if (objData.contentLink) != "" {
                alert.addAction(UIAlertAction(title:     "Object Link",  style: UIAlertAction.Style.default, handler: { _ in self.openUrl(scheme: (objData.contentLink)) } ))
            }
            
            if selFeeds.count > 0 {
                if selFeeds.first?.url != "" {
                    alert.addAction(UIAlertAction(title: "Share Source",  style: UIAlertAction.Style.default, handler: { _ in self.shareURLAction(url: (selFeeds.first?.url)!) } ))
                }
            }
            
            alert.addAction(UIAlertAction(title: "Cancel",     style: .cancel,  handler: { _ in self.resetSeletion() } ))
            alert.view.tintColor = UIColor.black
            alert.view.tintColorDidChange()

            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    @objc func resetSeletion() {
        for n in mainScene.rootNode.childNodes {
            n.removeAllAnimations()
            n.removeAllActions()
            n.isHidden = false
        }
        
        if (selectedNode != nil) {
            selectedNode?.removeAllAnimations()
        }
        
        selectedNode = nil
    }
    
    
}
