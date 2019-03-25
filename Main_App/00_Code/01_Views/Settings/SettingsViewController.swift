//
//  SettingsViewController.swift
//  aulae
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
    lazy var rlmSession: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    lazy var rlmFeeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
    
    
    let systemUpdateSpeedParamName = "systemUpdateSpeed"
    @IBOutlet var systemUpdateSpeedStepper: UIStepper!
    @IBOutlet var systemUpdateSpeedDisplay: UITextField!
    @IBAction func systemUpdateSpeedStepperAction(_ sender: UIStepper) {
        saveSettings(propName: systemUpdateSpeedParamName, propValue: Double(sender.value))
        updateUI()
    }
    
    let feeUpdateSpeedParamName = "feedUpdateSpeed"
    @IBOutlet var feedUpdateSpeedStepper: UIStepper!
    @IBOutlet var feedUpdateSpeedDisplay: UITextField!
    @IBAction func feedUpdateIntervalStepperAction(_ sender: UIStepper) {
        saveSettings(propName: feeUpdateSpeedParamName, propValue: Double(sender.value))
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
    
    let allowAudioParamName = "allowAudio"
    @IBOutlet var allowAudioSwitch: UISwitch!
    @IBAction func allowAudioSwitchAction(_ sender: UISwitch) {
        let boolDouble = Double(NSNumber(value: sender.isOn).intValue)
        saveSettings(propName: allowAudioParamName, propValue: boolDouble)
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
        if rlmSession.count > 0 {
            do {
                try realm.write {
                    switch propName {
                        
                    case systemUpdateSpeedParamName:
                        rlmSession.first!.sysUpdateInterval     = propValue
                        
                    case feeUpdateSpeedParamName:
                        rlmSession.first!.feedUpdateInterval    = propValue
                        
                    case scaleFactorParamName:
                        rlmSession.first!.scaleFactor           = propValue
                      
                    case allowAudioParamName:
                        rlmSession.first?.muteAudio             = Int(propValue) != 1
                        
                    case useDistanceParamName:
                        rlmSession.first!.distanceScale         = Int(propValue) == 1
                        
                    case autoUpdateParamName:
                        rlmSession.first!.autoUpdate            = Int(propValue) == 1
                        
                    case gpsToggleParamName:
                        rlmSession.first!.backgroundGps         = Int(propValue) == 1
                        
                    case showPlaceholderParamName:
                        rlmSession.first!.showPlaceholders      = Int(propValue) == 1
                        
                    case animationToggleParamName:
                        rlmSession.first!.allowAnimation        = Int(propValue) == 1
    
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
        feedUpdateSpeedDisplay.text      = String(Int(rlmSession.first!.feedUpdateInterval))
        feedUpdateSpeedStepper.value     = rlmSession.first!.feedUpdateInterval
        
        systemUpdateSpeedDisplay.text    = String(Int(rlmSession.first!.sysUpdateInterval))
        systemUpdateSpeedStepper.value   = rlmSession.first!.sysUpdateInterval
        
        scaleFactorDisplay.text          = String(Int(rlmSession.first!.scaleFactor))
        scaleFactorStepper.value         = rlmSession.first!.scaleFactor
        
        allowAudioSwitch.isOn            = rlmSession.first!.muteAudio         != true

        useDistanceSwitch.isOn           = rlmSession.first!.distanceScale    == true
        autoUpdateSwitch.isOn            = rlmSession.first!.autoUpdate       == true
        gpsToggleSwitch.isOn             = rlmSession.first!.backgroundGps    == true
        
        showPlaceholderSwitch.isOn       = rlmSession.first!.showPlaceholders == true
        animationToggleSwitch.isOn       = rlmSession.first!.allowAnimation   == true
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("SETTINGSVIEW: viewDidDisappear")
        self.navigationController?.popViewController(animated: true)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        print("WILLAPPEAR")
        updateUI()
    }

}
