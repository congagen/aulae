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
    lazy var rlmSystem:     Results<RLM_System> = { self.realm.objects(RLM_System.self) }()
    lazy var rlmSession: Results<RLM_Session> = { self.realm.objects(RLM_Session.self) }()
    
    lazy var rlmFeeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
    
    lazy var rlmCamera: Results<RLM_Camera> = { self.realm.objects(RLM_Camera.self) }()
    
    
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
    
    
    let locationToggleParamName = "animationToggle"
    @IBOutlet var locationSharingSwitch: UISwitch!
    @IBAction func locationSharingSwitchAction(_ sender: UISwitch) {
        let boolDouble = Double(NSNumber(value: sender.isOn).intValue)
        saveSettings(propName: locationToggleParamName, propValue: boolDouble)
        updateUI()
    }
    
    let cameraExposureParamName   = "cameraExposure"
    @IBOutlet var camExposureStepper: UIStepper!
    @IBOutlet var camExposureDisplay: UITextField!
    
    @IBAction func camExposureStepperAction(_ sender: UIStepper) {
        saveSettings(propName: cameraExposureParamName, propValue: Double(sender.value))
        updateUI()
    }
    
    let cameraContrastParamName   = "cameraContrast"
    @IBOutlet var camContrastStepper: UIStepper!
    @IBOutlet var camContrastDisplay: UITextField!
    
    @IBAction func camContrastStepperAction(_ sender: UIStepper) {
        saveSettings(propName: cameraContrastParamName, propValue: Double(sender.value))
        updateUI()
    }
    
    let cameraSaturationParamName = "cameraSaturation"
    @IBOutlet var camSaturationStepper: UIStepper!
    @IBOutlet var camSaturationDisplay: UITextField!
    
    @IBAction func camSaturationStepperAction(_ sender: UIStepper) {
        saveSettings(propName: cameraSaturationParamName, propValue: Double(sender.value))
        updateUI()
    }
    
    
    
    func saveSettings(propName: String, propValue: Double) {
        
        do {
            try realm.write {
                rlmSystem.first?.needsRefresh = true
            }
        } catch {
            print("Error: \(error)")
        }
        
        if rlmSession.count > 0 {
            do {
                try realm.write {
                    switch propName {
                        
                    case cameraExposureParamName:
                        rlmCamera.first!.exposureOffset         = propValue
                        
                    case cameraContrastParamName:
                        rlmCamera.first!.contrast               = propValue

                    case cameraSaturationParamName:
                        rlmCamera.first!.saturation             = propValue

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
                        
                    case locationToggleParamName:
                        rlmSession.first!.showPlaceholders      = Int(propValue) == 1
    
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
        
        locationSharingSwitch.isOn       = rlmSession.first!.showPlaceholders == true
        
        camExposureStepper.value         = rlmCamera.first!.exposureOffset
        camExposureDisplay.text          = String( Double(round(1000 * camExposureStepper.value)/1000))
        
        camContrastStepper.value         = rlmCamera.first!.contrast
        camContrastDisplay.text          = String( Double(round(1000 * camContrastStepper.value)/1000))
        
        camSaturationStepper.value       = rlmCamera.first!.saturation
        camSaturationDisplay.text        = String( Double(round(1000 * camSaturationStepper.value)/1000))
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
