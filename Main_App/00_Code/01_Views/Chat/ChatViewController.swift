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


class ChatViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var chatView: UITextView!
    @IBOutlet var chatInputField: UITextField!
    @IBOutlet var contentView: UIView!

    @IBOutlet var chatTableView: UITableView!
    
    @IBAction func doneBtnAction(_ sender: UIBarButtonItem) {
        endChat()
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    lazy var realm = try! Realm()
    lazy var rlmSession: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var rlmChatSession: Results<RLM_ChatSession> = { self.realm.objects(RLM_ChatSession.self) }()

    lazy var rlmFeeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
    
    
    let greetingMsg = "\n\n\n Mention /exit to return to viewport\n"
    let exitKeywords = ["/quit", "/exit", "exit", "quit"]
    
    var keyboardHeight: Int = 0
    var keyboardIsPresent = false
    var conv: String = ""
    var apiHeaderValue = ""
    var apiHeaderFeild = ""
    var keyboard = false
    
    var chatConvList = ["a"]
    
    func callApi(message: String) {
        print("callApi")
        
        if rlmChatSession.first!.apiUrl != "" {
            NetworkTools().postReq(
                completion: { r in self.handleResponseText(result: r) }, apiHeaderValue: apiHeaderValue,
                apiHeaderFeild: apiHeaderFeild, apiUrl: rlmChatSession.first!.apiUrl,
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
        print("handleResponseText")
        print(result)
        
        DispatchQueue.main.async {
            self.insertResponseText(chatData: result)
        }
    }
    
    func insertResponseText(chatData: Dictionary<String, AnyObject>) {
        print("insertResponseText")
        print(chatData)
        
        if chatData.keys.contains("chat_response") {
            if let rsp: String = (chatData["chat_response"] as? String) {
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
        
        do {
            try realm.write {
                rlmChatSession.first?.apiUrl = ""
            }
        } catch {
            print("Error: \(error)")
        }
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
                chatView.text = "\nYou: " + chatInputField.text! + "\n" + chatView.text
                
                if rlmChatSession.first?.apiUrl != "" {
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
        
        //let indexPath = IndexPath(row: 90, section: 0)
        //self.chatTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
    
    
    func initSession(){
        chatView.text = greetingMsg
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesEnded")
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }
    

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.detailTextLabel?.numberOfLines = 100
        cell.textLabel?.numberOfLines = 100
        
        cell.detailTextLabel?.text = "2019-06-06 00:15:22.1 34477+0200 Aulae[22 53:193477] [DYMTLIni tPlatform] platform 2019-06-06 00:15:2 2.13447 7+0200 Aulae[2253 :193477] [DYMTLIni tPlatform] platform"
        cell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
        
        if indexPath.item % 2 == 0 {
            cell.textLabel?.textAlignment = .left
            cell.detailTextLabel?.textAlignment = .left
        } else {
            cell.textLabel?.textAlignment = .right
            cell.detailTextLabel?.textAlignment = .right
        }
        
        var frame = cell.frame
        let newWidth = frame.width * 0.50
        let space = (frame.width - newWidth) / 2
        frame.size.width = newWidth
        frame.origin.x += space
        
        cell.frame = frame
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // TODO: Scale to fit chat message
        return 150
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesBegan")
        let ch: Int = Int(chatInputField.frame.maxY)
        let keyHeight: Int = Int(keyboardHeight) + ch
        print(keyHeight)
        
        if (Int(((touches.first?.location(in: self.view).y)!)) > keyHeight) {
            hideChatKeyboard()
        } else {
            chatInputField.becomeFirstResponder()
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSession()
        
        scrollView.isScrollEnabled = false
        configureCustomTextField(customTextField: chatInputField)
        
        chatInputField.delegate = self
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShowOrHide),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShowOrHide),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
        
        chatTableView.delegate = self
        chatTableView.dataSource = self
        
        let singleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self,action: #selector(viewWasTapped))
        singleTap.numberOfTapsRequired = 1
        singleTap.numberOfTouchesRequired = 1
        self.chatView.addGestureRecognizer(singleTap)
        self.chatView.isUserInteractionEnabled = true
        
        chatTableView.transform = CGAffineTransform(scaleX: 1, y: -1)
    }
    
    @objc func viewWasTapped(recognizer: UITapGestureRecognizer) {
        if(recognizer.state == .ended){
            keyboard = !keyboard
            
            if keyboard {
                chatInputField.becomeFirstResponder()
            } else {
                hideChatKeyboard()
            }
            
        }
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

