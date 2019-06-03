//
//  ChatViewController.swift
//  Aulae
//
//  Created by Tim Sandgren on 2019-05-28.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import UIKit
import Foundation

class ChatViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var chatView: UITextView!
    @IBOutlet var chatInputField: UITextField!
    @IBOutlet var contentView: UIView!
    
    
    var lastOffset: CGPoint! = CGPoint(x: 10, y: 10)
    var keyboardHeight: CGFloat! = 10

    
    @IBAction func sendMsgBtnAction(_ sender: UIButton) {
        chatView.text += "\n" + chatInputField.text!
    }
    
    
    @objc func keyboardWillShowOrHide(notification: NSNotification) {
        if let userInfo = notification.userInfo, let scrollView = scrollView, let durationValue = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] {
            if let keyboardSize = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                //let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
                let endRect = view.convert(keyboardSize, from: view.window)
                
                // Find out how much the keyboard overlaps the scroll view
                // We can do this because our scroll view's frame is already in our view's coordinate system
                let keyboardOverlap = scrollView.frame.maxY - endRect.origin.y
                
                // Set the scroll view's content inset to avoid the keyboard
                // Don't forget the scroll indicator too!
                scrollView.contentInset.bottom = keyboardOverlap
                scrollView.scrollIndicatorInsets.bottom = keyboardOverlap
                
                let duration = ((durationValue as AnyObject).doubleValue)!
                UIView.animate(withDuration: duration, delay: 0, options: .beginFromCurrentState, animations: {
                    self.view.layoutIfNeeded()
                }, completion: nil)
            }
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowOrHide), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowOrHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
   


    
}
