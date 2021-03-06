//
//  SettingsViewController.swift
//  aulae
//
//  Created by Tim Sandgren on 2019-02-21.
//  Copyright © 2019 Tim Sandgren. All rights reserved.
//

import UIKit
import Realm
import RealmSwift
import Foundation


class SettingsViewController: UITableViewController {

    lazy var realm = try! Realm()
    lazy var rlmSystem:  Results<RLM_SysSettings_117> = { self.realm.objects(RLM_SysSettings_117.self) }()
    lazy var rlmSession: Results<RLM_Session_117> = { self.realm.objects(RLM_Session_117.self) }()
    lazy var chatSessions: Results<RLM_ChatSess> = { self.realm.objects(RLM_ChatSess.self) }()
    
    lazy var rlmFeeds: Results<RLM_Feed> = { self.realm.objects(RLM_Feed.self) }()
    lazy var feedObjects: Results<RLM_Obj> = { self.realm.objects(RLM_Obj.self) }()
    lazy var rlmCamera: Results<RLM_CameraSettings> = { self.realm.objects(RLM_CameraSettings.self) }()
    
    @IBOutlet var usernameBtn: UIButton!

    let chatUsernameParamName = "chatUsername"
    var textField: UITextField? = nil
    func usernameTextField(textField: UITextField!)
    {
        if let _ = textField {
            self.textField = textField!
            textField.text! = ""
        }
    }
    
    @IBAction func editUsernameAction(_ sender: UIButton) {
        print("editUsernameAction")
        showEditUsernameAlert(aMessage: "")
    }
    
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
        super.viewWillAppear(true)
        updateUI()
    }
    
    
    @IBAction func closeBtnAction(_ sender: UIBarButtonItem) {
        UIOps().updateNavUiMode(navCtrl: self.navigationController!)
        self.navigationController?.dismiss( animated: true, completion: { super.viewDidAppear(true)} )
        self.view.removeFromSuperview()
    }
    
    
    func showEditUsernameAlert(aMessage: String?){
        let alert = UIAlertController(
            title: "Username", message: nil, preferredStyle: UIAlertController.Style.alert
        )
        
        alert.addTextField(configurationHandler: usernameTextField)
        alert.addAction(UIAlertAction(title: "Ok",     style: UIAlertAction.Style.default, handler: saveNewUsername))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel,  handler: nil))
        
        if traitCollection.userInterfaceStyle == .light {
            alert.view.tintColor = UIColor.black
        } else {
            alert.view.tintColor = UIColor.white
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func saveNewUsername(alertView: UIAlertAction!) {
        
        if textField?.text != nil {
            saveSettings(propName: chatUsernameParamName, propValue: 0, propString: textField!.text!)
        }
        
        updateUI()

        self.tableView.reloadData()
        self.tableView.reloadInputViews()
    }
    

    let autoUpdateParamName = "autoUpdate"
//    @IBOutlet var autoUpdateSwitch: UISwitch!
//    @IBAction func autoUpdateSwitchAction(_ sender: UISwitch) {
//        let boolDouble = Double(NSNumber(value: sender.isOn).intValue)
//        saveSettings(propName: autoUpdateParamName, propValue: boolDouble)
//        updateUI()
//    }
    
    
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
    
    let onlyLocalContentParamName   = "onlyLocalContent"
//    @IBOutlet var onlyLocalContentSwitch: UISwitch!
//    @IBAction func onlyLocalContentSwitchAction(_ sender: UISwitch) {
//        let boolDouble = Double(NSNumber(value: sender.isOn).intValue)
//        saveSettings(propName: onlyLocalContentParamName, propValue: boolDouble)
//        updateUI()
//    }
    
    
//    let darkModeParamName = "darkModeState"
//    @IBOutlet var darkModeSwitch: UISwitch!
//    @IBAction func darkModeSwitchAction(_ sender: UISwitch) {
//        let boolDouble = Double(NSNumber(value: sender.isOn).intValue)
//        saveSettings(propName: darkModeParamName, propValue: boolDouble)
//        updateUI()
//    }

    
    let gpsContentParamName = "gpsContent"
    @IBOutlet var gpsContentSwitch: UISwitch!
    @IBAction func gpsContentSwitchAction(_ sender: UISwitch) {
        let boolDouble = Double(NSNumber(value: sender.isOn).intValue)
        saveSettings(propName: gpsContentParamName, propValue: boolDouble)
        updateUI()
    }
    
    
    let locationSharingParamName = "locationSharing"
    @IBOutlet var locationSharingSwitch: UISwitch!
    @IBAction func locationSharingSwitchAction(_ sender: UISwitch) {
        let boolDouble = Double(NSNumber(value: sender.isOn).intValue)
        saveSettings(propName: locationSharingParamName, propValue: boolDouble)
        updateUI()
    }
    
    
    let cameraIsEnabledParamName   = "cameraIsEnabled"
    @IBOutlet var cameraIsEnabledSwitch: UISwitch!
    @IBAction func cameraIsEnabledSwitchAction(_ sender: UISwitch) {
        let boolDouble = Double(NSNumber(value: sender.isOn).intValue)
        saveSettings(propName: cameraIsEnabledParamName, propValue: boolDouble)
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
    
    
    func saveSettings(propName: String, propValue: Double, propString: String = "") {
        
        do {
            try realm.write {
                rlmSession.first?.needsRefresh = true
            }
        } catch {
            print("Error: \(error)")
        }
        
        if rlmSession.count > 0 {
            do {
                try realm.write {
                    switch propName {
                        
                    case cameraIsEnabledParamName:
                        rlmCamera.first!.isEnabled              = Int(propValue) == 1
                        
                    case cameraExposureParamName:
                        rlmCamera.first!.exposureOffset         = propValue
                        
                    case cameraContrastParamName:
                        rlmCamera.first!.contrast               = propValue

                    case cameraSaturationParamName:
                        rlmCamera.first!.saturation             = propValue

                    case systemUpdateSpeedParamName:
                        rlmSystem.first!.sysUpdateInterval      = propValue
                        
                    case feeUpdateSpeedParamName:
                        rlmSystem.first!.feedUpdateInterval     = propValue
                        
                    case scaleFactorParamName:
                        rlmSystem.first!.scaleFactor            = propValue
                      
                    case allowAudioParamName:
                        rlmSystem.first?.muteAudio              = Int(propValue) != 1
                        
                    case onlyLocalContentParamName:
                        rlmSystem.first?.onlyGpsContent         = Int(propValue) == 1
                        
//                    case darkModeParamName:
//                        rlmSystem.first?.uiMode                 = Int(propValue)
                        
                    case useDistanceParamName:
                        rlmSystem.first!.gpsScaling             = Int(propValue) == 1
                        
                    case autoUpdateParamName:
                        rlmSystem.first!.autoUpdate             = Int(propValue) == 1
                        
                    case locationSharingParamName:
                        rlmSystem.first!.locationSharing        = Int(propValue) == 1
                        
    
                    case chatUsernameParamName:
                        chatSessions.first?.username            = propString
                        
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
        //        autoUpdateSwitch.isOn            = rlmSession.first!.autoUpdate == true
        //        cameraIsEnabledSwitch.isOn       = rlmCamera.first?.isEnabled == true

        feedUpdateSpeedDisplay.text      = String(Int(rlmSystem.first!.feedUpdateInterval))
        feedUpdateSpeedStepper.value     = rlmSystem.first!.feedUpdateInterval
        
        systemUpdateSpeedDisplay.text    = String(Int(rlmSystem.first!.sysUpdateInterval))
        systemUpdateSpeedStepper.value   = rlmSystem.first!.sysUpdateInterval
        
        scaleFactorDisplay.text          = String(Int(rlmSystem.first!.scaleFactor))
        scaleFactorStepper.value         = rlmSystem.first!.scaleFactor
        
//        onlyLocalContentSwitch.isOn      = rlmSystem.first!.onlyGpsContent
        allowAudioSwitch.isOn            = rlmSystem.first!.muteAudio != true

        useDistanceSwitch.isOn           = rlmSystem.first!.gpsScaling == true
        locationSharingSwitch.isOn       = rlmSystem.first!.locationSharing == true
        
        camExposureStepper.value         = rlmCamera.first!.exposureOffset
        camExposureDisplay.text          = String( Double(round(1000 * camExposureStepper.value) / 1000))
        
        camContrastStepper.value         = rlmCamera.first!.contrast
        camContrastDisplay.text          = String( Double(round(1000 * camContrastStepper.value) / 1000))
        
        camSaturationStepper.value       = rlmCamera.first!.saturation
        camSaturationDisplay.text        = String( Double(round(1000 * camSaturationStepper.value) / 1000))
        
//        darkModeSwitch.isOn              = rlmSystem.first?.uiMode == 1

        for state: UIControl.State in [.normal, .highlighted, .disabled, .selected, .focused, .application, .reserved] {
            usernameBtn.setTitle(NSLocalizedString(chatSessions.first!.username, comment: ""), for: state)
        }

    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        UIOps().updateNavUiMode(navCtrl: self.navigationController!)
        
        do {
            try realm.write {
                rlmSession.first?.needsRefresh = false
            }
        } catch {
            print("Error: \(error)")
        }
        
        updateUI()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear: SettingsViewController")
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        UIOps().updateNavUiMode(navCtrl: self.navigationController!)
        
        do {
            try realm.write {
                rlmSession.first?.needsRefresh = false
            }
        } catch {
            print("Error: \(error)")
        }
        
        tableView.scrollToRow(at: IndexPath.init(row: 0, section: 0), at: .top, animated: false)

        updateUI()
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        print("viewDidDisappear: SettingsViewController")
//        tableView.scrollToRow(at: IndexPath.init(row: 0, section: 0), at: .top, animated: false)
//        self.navigationController?.popViewController(animated: true)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear: SettingsViewController")
        tableView.scrollToRow(at: IndexPath.init(row: 0, section: 0), at: .top, animated: false)
        updateUI()
    }


}
