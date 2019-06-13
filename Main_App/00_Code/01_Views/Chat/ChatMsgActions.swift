//
//  ChatMsgActions.swift
//  Aulae
//
//  Created by Tim Sandgren on 2019-06-13.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import ARKit

extension ChatViewController {
    
    
    func sharePhoto() {
//        let renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: [:])
//        renderer.scene = sceneView.scene
//        renderer.pointOfView = sceneView.pointOfView
//        let snapShot = renderer.snapshot(atTime: TimeInterval(0), with: CGSize(width: 100, height: 100), antialiasingMode: .none)
//
//        let imageToShare = [snapShot]
//        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
//        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook ]
//
//        activityViewController.popoverPresentationController?.sourceView = self.view
//        self.present(activityViewController, animated: true, completion: nil)
    }
    
    
    func shareText(text: String) {
        
        let textToShare = [ text ]
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
        alert.setValue(attributedString, forKey: "attributedMessage")
        
        return attributedString
    }
    
    
    func copyToClip(text: String) {
        UIPasteboard.general.string = text
    }
    
    
    func showActionMenu(cellText: String) {
        print("showSeletedNodeActions")

        let alert =  UIAlertController(
            title:   cellText,
            message: "",
            preferredStyle: UIAlertController.Style.alert
        )
        
        if (cellText) != "" {
            if let url = URL(string: cellText) {
                alert.addAction(UIAlertAction(
                    title: "Open in browser", style: UIAlertAction.Style.default, handler: { _ in self.openUrl(scheme: (cellText)) } ))
            }

            alert.addAction(UIAlertAction(
                title: "Copy to clipboard", style: UIAlertAction.Style.default, handler: { _ in self.copyToClip(text: (cellText)) } ))
        
            alert.addAction(UIAlertAction(
                title: "Share", style: UIAlertAction.Style.default, handler: { _ in self.shareText(text: cellText) } ))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel,  handler: nil ))
        alert.view.tintColor = UIColor.black
        alert.view.tintColorDidChange()
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    


    
    
}
