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
    lazy var rlmChatSession: Results<RLM_ChatSess> = { self.realm.objects(RLM_ChatSess.self) }()
    
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        UIOps().updateNavUiMode(navCtrl: self)
    }
    
    override func transition(from fromViewController: UIViewController, to toViewController: UIViewController, duration: TimeInterval, options: UIView.AnimationOptions = [], animations: (() -> Void)?, completion: ((Bool) -> Void)? = nil) {
        UIOps().updateNavUiMode(navCtrl: self)
        super.viewDidAppear(true)
    }
    
    override func didMove(toParent parent: UIViewController?) {
        UIOps().updateNavUiMode(navCtrl: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIOps().updateNavUiMode(navCtrl: self)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        UIOps().updateNavUiMode(navCtrl: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        UIOps().updateNavUiMode(navCtrl: self)
        super.viewDidAppear(animated)
    }

    override func viewWillAppear(_ animated: Bool) {
        UIOps().updateNavUiMode(navCtrl: self)
        super.viewWillAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        UIOps().updateNavUiMode(navCtrl: self)
    }

}
