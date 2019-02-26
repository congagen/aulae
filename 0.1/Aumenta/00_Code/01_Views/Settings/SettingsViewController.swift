//
//  SettingsViewController.swift
//  Aumenta
//
//  Created by Tim Sandgren on 2019-02-21.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import UIKit
import Realm
import RealmSwift
import Foundation


class SettingsViewController: UITableViewController {

    let realm = try! Realm()
    lazy var session: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var feeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
    
    
    // SYSTEM
    let feeUpdateSpeedParamName = "feedUpdateSpeed"
    @IBOutlet var feedUpdateSpeedStepper: UIStepper!
    @IBOutlet var feedUpdateSpeedDisplay: UITextField!
    @IBAction func feedUpdateIntervalStepperAction(_ sender: UIStepper) {
        saveSettings(propName: feeUpdateSpeedParamName, propValue: Double(sender.value))
        updateUI()
    }
    
    let contentUpdateSpeedParamName = "contentUpdateSpeed"
    @IBOutlet var contentUpdateSpeedStepper: UIStepper!
    @IBOutlet var contentUpdateSpeedDisplay: UITextField!
    @IBAction func contentUpdateSpeedStepperAction(_ sender: UIStepper) {
        saveSettings(propName: contentUpdateSpeedParamName, propValue: Double(sender.value))
        updateUI()
    }
    
    let autoUpdateParamName = "autoUpdate"
    @IBOutlet var autoUpdateSwitch: UISwitch!
    @IBAction func autoUpdateSwitchAction(_ sender: UISwitch) {
        let boolDouble = Double(NSNumber(value: sender.isOn).intValue)
        saveSettings(propName: autoUpdateParamName, propValue: boolDouble)
        updateUI()
    }
    
    let gpsToggleParamName = "gpsToggle"
    @IBOutlet var gpsToggleSwitch: UISwitch!
    @IBAction func gpsToggleSwitchAction(_ sender: UISwitch) {
        let boolDouble = Double(NSNumber(value: sender.isOn).intValue)
        saveSettings(propName: gpsToggleParamName, propValue: boolDouble)
        updateUI()
    }
    
    
    // CONTENT
    let scaleFactorParamName = "scaleFactor"
    @IBOutlet var scaleFactorStepper: UIStepper!
    @IBOutlet var scaleFactorDisplay: UITextField!
    @IBAction func scaleFactorStepperAction(_ sender: UIStepper) {
        saveSettings(propName: scaleFactorParamName, propValue: Double(sender.value))
        updateUI()
    }
    
    let useDistanceParamName = "useDistance"
    @IBOutlet var useDistanceSwitch: UISwitch!
    @IBAction func useDistanceSwitchAction(_ sender: UISwitch) {
        let boolDouble = Double(NSNumber(value: sender.isOn).intValue)
        saveSettings(propName: useDistanceParamName, propValue: boolDouble)
        updateUI()
    }
    
    let showPlaceholderParamName = "showPlaceholders"
    @IBOutlet var showPlaceholderSwitch: UISwitch!
    @IBAction func showPlaceholderSwitchAction(_ sender: UISwitch) {
        let boolDouble = Double(NSNumber(value: sender.isOn).intValue)
        saveSettings(propName: showPlaceholderParamName, propValue: boolDouble)
        updateUI()
    }
    
    let animationToggleParamName = "animationToggle"
    @IBOutlet var animationToggleSwitch: UISwitch!
    @IBAction func anitmationToggleSwitchAction(_ sender: UISwitch) {
        let boolDouble = Double(NSNumber(value: sender.isOn).intValue)
        saveSettings(propName: animationToggleParamName, propValue: boolDouble)
        updateUI()
    }
    
    
    func saveSettings(propName: String, propValue: Double) {
        if session.count > 0 {
            do {
                try realm.write {
                    switch propName {
                        
                    case feeUpdateSpeedParamName:
                        session.first!.feedUpdateInterval    = propValue
                        
                    case contentUpdateSpeedParamName:
                        session.first!.contentUpdateInterval = propValue
                        
                    case scaleFactorParamName:
                        session.first!.scaleFactor           = propValue
                      
                    case useDistanceParamName:
                        session.first!.distanceScale         = Int(propValue) == 1
                        
                    case autoUpdateParamName:
                        session.first!.autoUpdate            = Int(propValue) == 1
                        
                    case gpsToggleParamName:
                        session.first!.backgroundGps         = Int(propValue) == 1
                        
                    case showPlaceholderParamName:
                        session.first!.showPlaceholders      = Int(propValue) == 1
                        
                    case animationToggleParamName:
                        session.first!.allowAnimation        = Int(propValue) == 1
    
                    default:
                        break
                    }
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }
    

    func updateUI()  {
        feedUpdateSpeedDisplay.text      = String(Int(session.first!.feedUpdateInterval))
        feedUpdateSpeedStepper.value     = session.first!.feedUpdateInterval
        
        contentUpdateSpeedDisplay.text   = String(Int(session.first!.contentUpdateInterval))
        contentUpdateSpeedStepper.value  = session.first!.contentUpdateInterval
        
        scaleFactorDisplay.text          = String(Int(session.first!.scaleFactor))
        scaleFactorStepper.value         = session.first!.scaleFactor
        
        useDistanceSwitch.isOn           = session.first!.distanceScale    == session.first?.distanceScale
        autoUpdateSwitch.isOn            = session.first!.autoUpdate       == session.first?.autoUpdate
        gpsToggleSwitch.isOn             = session.first!.backgroundGps    == session.first?.backgroundGps
        
        showPlaceholderSwitch.isOn       = session.first!.showPlaceholders == session.first?.showPlaceholders
        animationToggleSwitch.isOn       = session.first!.allowAnimation   == session.first?.allowAnimation
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateUI()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        print("WILLAPPEAR")
        updateUI()
    }

}
