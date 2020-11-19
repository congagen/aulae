//
//  NodeActions.swift
//  aulae
//
//  Created by Tim Sandgren on 2019-03-04.
//  Copyright © 2019 Tim Sandgren. All rights reserved.
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
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        cancelAction.setValue(UIColor.black, forKey: "titleTextColor")
        
        if traitCollection.userInterfaceStyle == .light {
            activityViewController.view.tintColor = UIColor.black
        } else {
            activityViewController.view.tintColor = UIColor.white
        }
        
        //activityViewController.view.tintColor = UIColor.white
        activityViewController.view.tintColorDidChange()
        
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
    
    
    func styleAltertViewText() -> NSAttributedString{
        let strings = [
            ["text" : "My String red\n", "color" : UIColor.blue],
            ["text" : "My string green", "color" : UIColor.green]
        ];
        
        let attributedString = NSMutableAttributedString()
        
        for configDict in strings {
            if let color = configDict["color"] as? UIColor, let text = configDict["text"] as? String {
                attributedString.append(
                    NSAttributedString(
                        string: text, attributes: [NSAttributedString.Key.foregroundColor : color]
                    )
                )
            }
        }
        
        let alert = UIAlertController(title: "Title", message: "", preferredStyle: .alert)
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        alert.setValue(attributedString, forKey: "attributedMessage")
        
        return attributedString
    }
    
    
    func showNodeInfo(selNode: ContentNode) {
        
        let alert =  UIAlertController(
            title:   (selNode.title),
            message: "\n" + selNode.info,
            preferredStyle: UIAlertController.Style.alert
        )
        
        let act = UIAlertAction(title: "Done",  style: UIAlertAction.Style.default, handler: nil )
        
        if traitCollection.userInterfaceStyle == .light {
            alert.view.tintColor = UIColor.black
            act.setValue(UIColor.black, forKey: "titleTextColor")
        } else {
            alert.view.tintColor = UIColor.white
            act.setValue(UIColor.white, forKey: "titleTextColor")
        }
        
        alert.addAction(act)
        self.present(alert, animated: true, completion: nil)

    }
    
    
    func openChatWindow(sessionId: String, apiUrl: String, selNode: ContentNode) {
        
        do {
            try realm.write {
                rlmChatSession.first?.apiUrl    = selNode.chatURL
                rlmChatSession.first?.agentName = selNode.name ?? ""
                rlmChatSession.first?.agentId   = selNode.title
                rlmChatSession.first?.agentInfo = selNode.info
            }
        } catch {
            print("Error: \(error)")
        }

        if selectedNode != nil {
            do {
                try realm.write {
                    rlmChatSession.first?.sessionUUID = sessionId
                    rlmChatSession.first?.apiUrl = apiUrl
                }
            } catch {
                print("Error: \(error)")
            }
        }
        
        showChatView()
    }
    
    
    func showSeletedNodeActions(selNode: ContentNode) {
        print("showSeletedNodeActions")
        
        let alert =  UIAlertController(
            title:   selNode.feedName,
            message: (selNode.title),
            preferredStyle: UIAlertController.Style.actionSheet
        )
        
        if (selNode.info) != "" {
            alert.addAction(
                UIAlertAction(title: "Show Info", style: UIAlertAction.Style.default, handler: { _ in self.showNodeInfo(selNode: selNode) } ))
        }
        
        if selNode.chatURL != "" {
            alert.addAction(UIAlertAction(title: "Open Chat",  style: UIAlertAction.Style.default, handler: {
                _ in self.openChatWindow(sessionId: self.rlmChatSession.first!.apiUrl, apiUrl: self.rlmChatSession.first!.apiUrl, selNode: selNode)
            } ))
        } else {
            print(selNode.chatURL)
        }

        if (selNode.contentURL) != "" {
            alert.addAction(UIAlertAction(title: "Open Link", style: UIAlertAction.Style.default, handler: { _ in self.openUrl(scheme: (selNode.contentURL)) } ))
        }
        
        if selNode.feedUrl != "" && selNode.feedTopic == "" {
            alert.addAction(
                UIAlertAction(title: "Share Source", style: UIAlertAction.Style.default, handler: {_ in self.shareURLAction(url: (selNode.feedUrl)) }))
        }
        
        let hideAction = UIAlertAction(title: "Hide", style: UIAlertAction.Style.default, handler: { _ in self.muteSourceAction(feedID: selNode.feedId) } )
        alert.addAction(hideAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(cancelAction)
        
        if traitCollection.userInterfaceStyle == .light {
            alert.view.tintColor = UIColor.black
            cancelAction.setValue(UIColor.black, forKey: "titleTextColor")
        } else {
            alert.view.tintColor = UIColor.white
            cancelAction.setValue(UIColor.white, forKey: "titleTextColor")
        }
        
        //alert.view.tintColor = UIColor.black
        alert.view.tintColorDidChange()
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
}
