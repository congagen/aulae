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
        
    }
    
    
    func openUrl(scheme: String) {
        if let url = URL(string: scheme) {
            if #available(iOS 10, *) {
                UIApplication.shared.open(
                    url, options: [:], completionHandler: { (success) in print("Open \(scheme): \(success)") }
                )
            } else {
                let success = UIApplication.shared.openURL(url)
                print("Open \(scheme): \(success)")
            }
        }
    }
    
    
    func muteSourceAction(feedID: String) {
        
        if rlmFeeds.filter({$0.id == feedID}).count > 0 {
            let f = rlmFeeds.filter({$0.id == feedID}).first
            
            do {
                try realm.write {
                    f!.active = false
                }
            } catch {
                print("Error: \(error)")
            }
        }
        
        hideNodesWithId(nodeId: feedID)
    }
    
    
    func shoNodeInfo(selNode: ContentNode) {
        
        let alert =  UIAlertController(
            title:   (selNode.title),
            message: selNode.info,
            preferredStyle: UIAlertController.Style.actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "Done",  style: UIAlertAction.Style.default, handler: nil ))
        alert.view.tintColor = UIColor.black
        self.present(alert, animated: true, completion: nil)

    }
    
    func openChatWindow() {
        self.ChatView.isHidden = false
        
    }
    
    
    func showSeletedNodeActions(selNode: ContentNode) {
        print("showSeletedNodeActions")
        
        selectedNodeChatUrl = ""
        let contentLinkItems = selNode.contentLink.components(separatedBy: " ")
        let contentLinkItemA = contentLinkItems[0]
    
        if contentLinkItems.count >= 2 {
            if contentLinkItems[1] != "" {
                selectedNodeChatUrl = contentLinkItems[1]
            }
        }
        
        do {
            try realm.write {
                rlmChatSession.first?.apiUrl = selectedNodeChatUrl
                rlmChatSession.first?.agentName = selNode.name ?? ""
                rlmChatSession.first?.agentId = selNode.id
            }
        } catch {
            print("Error: \(error)")
        }
        
        let alert =  UIAlertController(
            title:   selNode.feedName,
            message: (selNode.title),
            preferredStyle: UIAlertController.Style.actionSheet
        )
        
        if (selNode.info) != "" {
            alert.addAction(UIAlertAction(title: "Show Info",  style: UIAlertAction.Style.default, handler: { _ in self.shoNodeInfo(selNode: selNode) } ))
        }
        
        if (rlmChatSession.first?.apiUrl) != "" && !(rlmChatSession.first?.apiUrl == nil) {
            alert.addAction(UIAlertAction(title: "Open Chat",  style: UIAlertAction.Style.default, handler: { _ in self.openChatWindow() } ))
        }

        if (contentLinkItemA) != "" {
            alert.addAction(UIAlertAction(title: "Open Link",  style: UIAlertAction.Style.default, handler: { _ in self.openUrl(scheme: (contentLinkItemA)) } ))
        }
        
        if selNode.feedUrl != "" && selNode.feedTopic == "" {
            alert.addAction(
                UIAlertAction(title: "Share Source", style: UIAlertAction.Style.default, handler: {_ in self.shareURLAction(url: (selNode.feedUrl)) }))
        }
        
        let hideAction = UIAlertAction(title: "Hide", style: UIAlertAction.Style.default, handler: { _ in self.muteSourceAction(feedID: selNode.feedId) } )
        alert.addAction(hideAction)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel,  handler: nil ))
        alert.view.tintColor = UIColor.black
        alert.view.tintColorDidChange()

        self.present(alert, animated: true, completion: nil)
    }
    
    
}
