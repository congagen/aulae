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

    
    // SYSTEM
    @IBOutlet var feedUpdateSpeedStepper: UIStepper!
    @IBOutlet var feedUpdateSpeedDisplay: UITextField!
    @IBAction func feedUpdateIntervalStepperAction(_ sender: UIStepper) {
        print("Editing feedUpdateSpeedStepperAction")
        print(sender.value)
        
        feedUpdateSpeedDisplay.text = String(Int(sender.value))
    }
    
    
    @IBOutlet var contentUpdateSpeedStepper: UIStepper!
    @IBOutlet var contentUpdateSpeedDisplay: UITextField!
    @IBAction func contentUpdateSpeedStepperAction(_ sender: UIStepper) {
    }
    
    
    @IBOutlet var autoUpdateSwitch: UISwitch!
    @IBAction func autoUpdateSwitchAction(_ sender: UISwitch) {
    }
    
    
    @IBOutlet var gpsToggleSwitch: UISwitch!
    @IBAction func gpsToggleSwitchAction(_ sender: UISwitch) {
    }
    
    
    // CONTENT
    @IBOutlet var placeholderSwitch: UISwitch!
    @IBAction func placeholderSwitchAction(_ sender: UISwitch) {
    }
    
    @IBOutlet var animationToggleSwitch: UISwitch!
    @IBAction func anitmationToggleSwitchAction(_ sender: UISwitch) {
    }
    
    
    
    
    func updateAll()  {
        
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    

    override func viewWillAppear(_ animated: Bool) {
        print("WILLAPPEAR")
    }

}
