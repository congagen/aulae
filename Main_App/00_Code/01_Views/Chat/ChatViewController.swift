//
//  ChatViewController.swift
//  Aulae
//
//  Created by Tim Sandgren on 2019-05-28.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import UIKit
import Foundation
import Realm
import RealmSwift


class ChatViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var chatView: UITextView!
    @IBOutlet var chatInputField: UITextField!
    @IBOutlet var contentView: UIView!
    
    var chatApiUrl = ""
    
    lazy var realm = try! Realm()
    lazy var rlmSession: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var rlmChatSession: Results<RLM_ChatSession> = { self.realm.objects(RLM_ChatSession.self) }()

    lazy var rlmFeeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
    
    
    let greetingMsg = "\n\n Mention /exit to return \n"
    let exitKeywords = ["/quit", "/exit", "exit", "quit"]
    
    var keyboardHeight: Int = 0
    var keyboardIsPresent = false
    var conv: String = ""
    var apiHeaderValue = ""
    var apiHeaderFeild = ""
    
    
    func callApi(message: String) {
        print("callApi")
        
        if chatApiUrl != "" {
            NetworkTools().postReq(
                completion: { r in self.handleResponseText(result: r) }, apiHeaderValue: apiHeaderValue,
                apiHeaderFeild: apiHeaderFeild, apiUrl: chatApiUrl,
                reqParams: [
                    "lat": "",
                    "lng": "",
                    "kwd": "",
                    "sid": (rlmSession.first?.sessionUUID)!,
                    "chat_msg": message
                ]
            )
        }
    }
    
    
    @objc func handleResponseText(result: Dictionary<String, AnyObject>) {
        print("insertResponseText")
        print(result)
        
        if result.keys.contains("chat_response") {
            if let rsp: String = (result["chat_response"] as? String) {
                chatView.text = "\n" + rsp + "\n" + chatView.text
            }
        }
    }
    
 
    func endChat() {
        self.view.superview?.isHidden = true
        hideChatKeyboard()
        dismissKeyboard()
        chatView.text = greetingMsg
        chatInputField.text = ""
    }
    
    
    @objc func sendMessage() {
        print("sendMessage")
        print(keyboardHeight)
        
        if chatView.text == greetingMsg {
           chatView.text = ""
        }
        
        if exitKeywords.contains(chatInputField.text!.lowercased()) {
            endChat()
        } else {
            if chatInputField.text! != "" {
                chatView.text = "\n You: " + chatInputField.text! + "\n" + chatView.text
                
                if rlmChatSession.first?.apiUrl != "" {
                    chatApiUrl = rlmChatSession.first!.apiUrl
                    callApi(message: chatInputField.text!)
                }
                
                chatInputField.text = ""
            }
        }
        
        if chatInputField.text == "" {
            print("chatInputField.text! !=")
            hideChatKeyboard()
        }
        
        print("sendBtnPressed")
    }
    
    @objc func hideChatKeyboard() {
        print("hideChatKeyboard")
        print(keyboardHeight)
        
        if chatInputField.text == "" {
            let tap: UITapGestureRecognizer = UITapGestureRecognizer(
                target: self, action: #selector(dismissKeyboard)
            )
            
            tap.cancelsTouchesInView = false
            view.addGestureRecognizer(tap)
        }
    }
    
    
    @objc func dismissKeyboard() {
        print("dismissKeyboard")
        print(keyboardHeight)
        
        view.endEditing(true)
    }
    
    
    func configureCustomTextField(customTextField: UITextField) {
        print("configureCustomTextField")

        customTextField.placeholder = NSLocalizedString("Message", comment: "")
        customTextField.autocorrectionType = .default
        customTextField.returnKeyType = .send
    }
    
    
    @objc func keyboardWillShowOrHide(notification: NSNotification) {
        print("keyboardWillShowOrHide")
        print(keyboardHeight)

        print("keyboardWillShowOrHide")
        if let userInfo = notification.userInfo,
            let scrollView = scrollView,
            let durationValue = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] {
            
            print("userInfo")
            if let keyboardSize = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                print("keyboardSize")
                keyboardHeight = Int(keyboardSize.maxY)
                
                scrollView.isScrollEnabled = true

                let endRect = view.convert(keyboardSize, from: view.window)
                let keyboardOverlap = scrollView.frame.maxY - endRect.origin.y
                
                scrollView.contentInset.bottom = keyboardOverlap
                scrollView.scrollIndicatorInsets.bottom = keyboardOverlap
                
                let duration = ((durationValue as AnyObject).doubleValue)!
                
                UIView.animate(withDuration: duration, delay: 0, options: .beginFromCurrentState, animations: {
                    self.view.layoutIfNeeded()
                }, completion: {_ in scrollView.isScrollEnabled = false})
            }
        }
    }
    

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        let ch: Int = Int(chatInputField.frame.maxY)
        let keyHeight: Int = Int(keyboardHeight) + ch
        print(keyHeight)

        if (Int(((touches.first?.location(in: self.view).y)!)) > keyHeight) {
            hideChatKeyboard()
        }
    }
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        print("textFieldDidEndEditing")
        sendMessage()
    }
    
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        print("textFieldDidEndEditing")
        sendMessage()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("textFieldShouldReturn")
        sendMessage()
        return true
    }
    
    
    func initSession(){
        chatView.text = greetingMsg
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSession()
        
        scrollView.isScrollEnabled = false
        configureCustomTextField(customTextField: chatInputField)
        
        chatInputField.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShowOrHide),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShowOrHide),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
    }
    

    
}








//    @objc func hideKeyboardNow(notification: NSNotification) {
//        print("hideKeyboardNow")
//        self.hideKeyboard()
//    }
//
//
//    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
//        return true
//    }


//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        print("textFieldShouldReturn")
//        return true
//    }

