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


struct ChatMessage {
    var message: String = ""
    var isIncomming: Bool = false
}


class ChatViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    lazy var realm = try! Realm()
    
    lazy var rlmSession:     Results<RLM_Session_117> = { self.realm.objects(RLM_Session_117.self) }()
    lazy var rlmSystem:     Results<RLM_SysSettings_117> = { self.realm.objects(RLM_SysSettings_117.self) }()

    lazy var rlmFeeds:       Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects:    Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
    
    lazy var rlmChatSession: Results<RLM_ChatSess> = { self.realm.objects(RLM_ChatSess.self) }()
    lazy var rlmChatMsgs:    Results<RLM_ChatMessage> = { self.realm.objects(RLM_ChatMessage.self) }()

    fileprivate let cellId = "cell"
    
    var curAgentName = ""
    var sessionID = ""
    let greetingMsg = "\n\n\n Mention /exit to return to viewport\n"
    let exitKeywords = ["/quit", "/exit", "exit", "quit"]

    var keyboardHeight: Int = 0
    var apiHeaderValue = ""
    var apiHeaderFeild = ""
    var keyboard = false
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var chatView: UITextView!
    @IBOutlet var chatInputField: UITextField!
    @IBOutlet var contentView: UIView!
    @IBOutlet var chatTableView: UITableView!
    
    @IBOutlet var fxBg: UIVisualEffectView!
    @IBAction func toggleBgAction(_ sender: UIBarButtonItem) {
        fxBg.isHidden = !fxBg.isHidden
    }
    
    
    @IBAction func doneBtnAction(_ sender: UIBarButtonItem) {
        endChat()
        self.navigationController?.dismiss(animated: true, completion: nil)
        self.view.removeFromSuperview()
    }
    
    @IBOutlet var navBarTitle: UINavigationItem!
    

    func addMessage(msgText: String, incomming: Bool) {
        print("addMessage: " + msgText)
        let chatMsg  = RLM_ChatMessage()
        let indexPos = rlmChatMsgs.filter({$0.apiId == self.rlmChatSession.first!.apiUrl}).count + 1
    
        do {
            try realm.write {
                chatMsg.indexPos     = indexPos
                chatMsg.apiId        = rlmChatSession.first!.apiUrl
                chatMsg.msgText      = msgText
                chatMsg.isIncomming  = incomming
                self.realm.add(chatMsg)
            }
        } catch {
            print("Error: \(error)")
        }
        
        chatTableView.reloadData()
    }

    
    func callApi(message: String) {
        print("callApi")
        
        if rlmChatSession.first!.apiUrl != "" {
            NetworkTools().postReq(
                completion: { r in self.handleResponseText(result: r) }, apiHeaderValue: apiHeaderValue,
                apiHeaderFeild: apiHeaderFeild, apiUrl: rlmChatSession.first!.apiUrl,
                reqParams: [
                    "username": rlmChatSession.first!.username,
                    "agent_id": rlmChatSession.first!.agentId,
                    
                    "sid":  (rlmSession.first?.sessionUUID)!,
                    "lat":  rlmSystem.first!.locationSharing ? String(rlmSession.first!.currentLat) : "0",
                    "lng":  rlmSystem.first!.locationSharing ? String(rlmSession.first!.currentLng) : "0",
                    "alt":  rlmSystem.first!.locationSharing ? String(rlmSession.first!.currentAlt) : "0",
                    
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
                addMessage(msgText: rsp, incomming: true)
            }
        }
        
        chatTableView.reloadData()
    }
    
    
    func endChat() {
        hideChatKeyboard()
        dismissKeyboard()
        chatInputField.text = ""
        
        do {
            try realm.write {
                rlmChatSession.first?.apiUrl = ""
            }
        } catch {
            print("Error: \(error)")
        }
        
//        super.viewWillDisappear(true)
//        self.navigationController?.isNavigationBarHidden = true
    }
    
    
    @objc func sendMessage() {
        print("sendMessage")
        print(keyboardHeight)

        if chatInputField.text! != "" {
            addMessage(msgText: chatInputField.text!, incomming: false)
            
            if rlmChatSession.first?.apiUrl != "" {
                callApi(message: chatInputField.text!)
            }
        }

        if chatInputField.text == "" {
            print("chatInputField.text! !=")
            hideChatKeyboard()
        }
        
        chatInputField.text = ""
        chatTableView.reloadData()
        chatTableView.reloadInputViews()
    }
    
    
    @objc func hideChatKeyboard() {
        print("hideChatKeyboard")
        print(keyboardHeight)
        
//        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
//            target: self, action: #selector(dismissKeyboard)
//        )
//        tap.cancelsTouchesInView = false
//        view.addGestureRecognizer(tap)
        
    }
    
    
    @objc func dismissKeyboard() {
        print("dismissKeyboard")
        print(keyboardHeight)
        
        chatInputField.resignFirstResponder()
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

        if let userInfo = notification.userInfo, let scrollView = scrollView, let durationValue = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] {
            scrollView.isScrollEnabled = true

            if let keyboardSize = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                print("keyboardSize")
                keyboardHeight = Int(keyboardSize.maxY)
                
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
    

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sessionMsgs = rlmChatMsgs.filter({$0.apiId == self.rlmChatSession.first?.apiUrl})
        let reverseIdx  = sessionMsgs.count - (indexPath.item + 1) + 1
        let msgForIdx   = sessionMsgs.filter({$0.indexPos == reverseIdx})

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ChatTableViewCell
        cell.backgroundColor = .clear
        cell.selectionStyle = .none

        if msgForIdx.count > 0 {
            cell.messageLabel.text = msgForIdx.first?.msgText
            cell.isIncomming       = msgForIdx.first?.isIncomming
        } else {
            print("ERROR: cellForRowAt: " + String(reverseIdx))
            cell.messageLabel.text = "Hmm..."
            cell.isIncomming       = false
        }
    
        cell.messageLabel.transform = CGAffineTransform(scaleX: 1, y: -1)
        return cell
    }
    
    
    func handleSelectedText(cellText: String) {
        print(cellText)
        
    }
    

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let sessionMsgs = rlmChatMsgs.filter({$0.apiId == self.rlmChatSession.first?.apiUrl})
        let reverseIdx  = sessionMsgs.count - (indexPath.item + 1) + 1
        let msgForIdx   = sessionMsgs.filter({$0.indexPos == reverseIdx})
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ChatTableViewCell
        cell.transform = CGAffineTransform(scaleX: 1, y: -1)

        if msgForIdx.count > 0 {
            
            let actionSheet = UITableViewRowAction(style: .normal, title: "...") { (rowAction, indexPath) in
                self.showActionMenu(cellText: msgForIdx.first!.msgText)
            }
            actionSheet.backgroundColor = UIColor(white: 1, alpha: 0.001)

            return [actionSheet]
        } else {
            return []
        }
        
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesEnded")
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sessionMsgs = rlmChatMsgs.filter({$0.apiId == self.rlmChatSession.first?.apiUrl})
        print("Msg Count: " + String(sessionMsgs.count))
        
        return sessionMsgs.count
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
    

    func initSession() {
        print("ChatView: refreshChatView")
        
        let msgCount = rlmChatMsgs.filter({$0.apiId == self.rlmChatSession.first?.apiUrl}).count
        
        if rlmChatSession.first?.apiUrl != "" && msgCount == 0 {
            callApi(message: "")
        }
        
        super.viewWillDisappear(false)
        
        if chatTableView != nil {
            chatTableView.reloadData()
        }
    }
    

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("textFieldShouldReturn")
        
        if chatInputField.text! != "" {
            sendMessage()
        }
        
        return true
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear: ChatView")
        chatTableView.reloadData()
    }

    
    @objc func viewWasTapped(recognizer: UITapGestureRecognizer) {
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "keyboardWillShowNotification")))
        
        if(recognizer.state == .ended){
            keyboard = !keyboard
            if keyboard {
                chatInputField.becomeFirstResponder()
            } else {
                hideChatKeyboard()
            }
        }
    }
    
    
    override func viewDidLoad() {
        print("ChatView: viewDidLoad")
        
        super.viewDidLoad()
        initSession()
        
        scrollView.isScrollEnabled = false
        configureCustomTextField(customTextField: chatInputField)
        
        chatInputField.delegate = self
        chatTableView.delegate = self
        chatTableView.dataSource = self
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShowOrHide),
            name: UIResponder.keyboardWillShowNotification, object: nil)

        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShowOrHide),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
        
        curAgentName = rlmChatSession.first!.agentId
        navBarTitle.title = rlmChatSession.first?.agentId
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self, action: #selector(dismissKeyboard)
        )
        
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        let singleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewWasTapped))
        singleTap.numberOfTapsRequired = 1
        singleTap.numberOfTouchesRequired = 1
        self.chatView.addGestureRecognizer(singleTap)
        self.chatView.isUserInteractionEnabled = true
        
        chatTableView.separatorStyle = .none
        chatTableView.register(ChatTableViewCell.self, forCellReuseIdentifier: cellId)
        chatTableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        chatTableView.reloadData()
        
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "keyboardWillShowNotification")))
    }
    
    
}








//    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
//        return true
//    }

























//let mockupMsgs = [
//    ChatMessage(message: "Lorenz tulip line flying rhombus hexagonal euphoric joyous synthesis meta caracal rose under squirrel?", isIncomming: false),
//    ChatMessage(message: "Is wombat reason neon perfecting towering spirit aural", isIncomming: true),
//    ChatMessage(message: "Intersecting lorenz is magenta spirited silicon fluorescent spatial to shimmering caracal rising clear ", isIncomming: false),
//    ChatMessage(message: "Perfect audible line hamster harmony ", isIncomming: false),
//    ChatMessage(message: "Yes?", isIncomming: true),
//    ChatMessage(message: "Longitude lattice infinite lorenz lateral lemon rhombus hexagon eternal. Aural line lorenz mint gaussian curve frenzied hoovering wombat to clouds fluorescent vast. Levitating tulip sine delirious gerbil ideal rambling beaming concave curve? Delirious triangular pu", isIncomming: true),
//    ChatMessage(message: "winged?", isIncomming: false),
//    ChatMessage(message: "Be eternal rose infinite maybe perfecting could energetic gerbil green.", isIncomming: true),
//    ChatMessage(message: "Triangular spatial pinwheel over spectral levitating gerbil bright towering hoovering.", isIncomming: false),
//    ChatMessage(message: "Latent spirit silicon meta is cantor bright. Triangular servals clear circus jesting pinwheel", isIncomming: false),
//    ChatMessage(message: "Is wombat reason neon perfecting towering spirit aural vertex cantor koch flying meta?", isIncomming: true),
//    ChatMessage(message: "Latent spirit silicon meta is cantor bright. Triangular servals clear circus jesting pinwheel", isIncomming: false),
//    ChatMessage(message: "horizontal vast linear opal squirrel perhaps levitating granular?", isIncomming: true)
//]
