//
//  DefaultNVC.swift
//  Aulae
//
//  Created by Tim Sandgren on 2019-06-13.
//  Copyright © 2019 Tim Sandgren. All rights reserved.
//

import UIKit
import Foundation
import UIKit

import Realm
import RealmSwift


class DefaultNVC: UINavigationController {

    lazy var realm = try! Realm()
    lazy var rlmSystem: Results<RLM_SysSettings_117> = { self.realm.objects(RLM_SysSettings_117.self) }()
    lazy var rlmSession: Results<RLM_Session_117> = { self.realm.objects(RLM_Session_117.self) }()
    lazy var rlmChatSession: Results<RLM_ChatSess> = { self.realm.objects(RLM_ChatSess.self) }()
    
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear: DefaultNVC")
        
        UIOps().updateNavUiMode(navCtrl: self)
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear: DefaultNVC")
        super.viewWillAppear(animated)

        UIOps().updateNavUiMode(navCtrl: self)
    }

    override func viewDidLoad() {
        print("viewDidLoad: DefaultNVC")

        super.viewDidLoad()
        UIOps().updateNavUiMode(navCtrl: self)
    }

}
