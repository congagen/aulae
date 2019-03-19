//
//  AppDelegate.swift
//  MeIcon
//
//  Created by Tim Sandgren on 2018-11-21.
//  Copyright © 2018 Tim Sandgren. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    @IBOutlet var menu: NSMenu!
    
    @IBOutlet var menuItemUpdate: NSMenuItem!
    @IBAction func manuItemUpdateAction(_ sender: NSMenuItem) {
        
    }
    
    @IBOutlet var menuItemQuit: NSMenuItem!
    @IBAction func manuItemQuitAction(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
    @IBOutlet var menuItemConfigure: NSMenuItem!
    @IBAction func menuItemConfigureAction(_ sender: Any) {
    
    }
    

    @objc func printQuote(_ sender: Any?) {
        let quoteText = "Never put off until tomorrow what you can do the day after tomorrow."
        let quoteAuthor = "Mark Twain"
        
        print("\(quoteText) — \(quoteAuthor)")
    }

    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem.button?.title = "MeIcon"
        statusItem.menu = menu
        
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("StatusBarButtonImage"))
            button.action = #selector(printQuote(_:))
            button.sizeThatFits(NSSize(width: 14, height: 14))
        }
        
        menuItemUpdate.title = "Refresh"
        menuItemQuit.title = "Quit"
    }

    
    func applicationWillTerminate(_ aNotification: Notification) {
    }


}

