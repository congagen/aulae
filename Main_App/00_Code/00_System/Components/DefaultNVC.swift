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
    

    
    override func viewWillAppear(_ animated: Bool) {
        UIOps().updateNavUiMode(navCtrl: self, darkMode: rlmSystem.first?.uiMode == 1)
    }
    
    override func viewWillLayoutSubviews() {
        UIOps().updateNavUiMode(navCtrl: self, darkMode: rlmSystem.first?.uiMode == 1)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        UIOps().updateNavUiMode(navCtrl: self, darkMode: rlmSystem.first?.uiMode == 1)
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        UIOps().updateNavUiMode(navCtrl: self, darkMode: rlmSystem.first?.uiMode == 1)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIOps().updateNavUiMode(navCtrl: self, darkMode: rlmSystem.first?.uiMode == 1)
    }
    

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIOps().updateNavUiMode(navCtrl: self, darkMode: rlmSystem.first?.uiMode == 1)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
