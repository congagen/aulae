//
//  DefaultNVC.swift
//  Aulae
//
//  Created by Tim Sandgren on 2019-06-13.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import UIKit
import Foundation
import UIKit

import Realm
import RealmSwift


class DefaultNVC: UINavigationController {

    lazy var realm = try! Realm()
    lazy var rlmSystem: Results<RLM_SysSettings> = { self.realm.objects(RLM_SysSettings.self) }()
    lazy var rlmSession: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var rlmChatSession: Results<RLM_ChatSession> = { self.realm.objects(RLM_ChatSession.self) }()
    
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        UIOps().updateNavUiMode(navCtrl: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        UIOps().updateNavUiMode(navCtrl: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        UIOps().updateNavUiMode(navCtrl: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    
        setNeedsStatusBarAppearanceUpdate()
        UIOps().updateNavUiMode(navCtrl: self)
    }

}
