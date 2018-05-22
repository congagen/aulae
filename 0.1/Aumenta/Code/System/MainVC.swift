//
//  MainVC.swift
//  ArkitTest
//
//  Created by Tim Sandgren on 2018-05-22.
//  Copyright © 2018 Abstraqata. All rights reserved.
//

import UIKit
import Realm
import RealmSwift

class MainVC: UITabBarController {

    lazy var realm = try! Realm()
    
    lazy var session: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var sources: Results<RLM_Source> = { self.realm.objects(RLM_Source.self) }()
    
    var mainUpdateTimer = Timer()

    
    func updateSession(){
        
        // If near and notify -> Send notification
        
    }

    
    func updateSources(){
        for s in sources {
            //
            
            print(s.id)
            print(s.active)
            print(s.lat)
            print(s.lng)
            print(s.date)

            
        }
    }
    
    
    @objc func mainUpdate() {
        
        if session.count < 1 {
            updateSources()
            updateSources()
            
            if mainUpdateTimer.timeInterval != session[0].updateInterval { mainUpdateTimer.invalidate() }
            
            if !mainUpdateTimer.isValid {
                mainUpdateTimer = Timer.scheduledTimer(
                    timeInterval: session[0].updateInterval,
                    target: self, selector: #selector(mainUpdate),
                    userInfo: nil, repeats: true)
            }
        }
    }
    
    
    func initSession(){
        if session.count < 1 {
            let sess = RLM_Session()
            
            do {
                try realm.write {
                    self.realm.add(sess)
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSession()
        mainUpdate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}
