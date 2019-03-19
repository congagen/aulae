//
//  IconViewController.swift
//  MeIcon
//
//  Created by Tim Sandgren on 2019-03-19.
//  Copyright © 2019 Tim Sandgren. All rights reserved.
//

import Cocoa

class IconViewController: NSViewController {
    
    
    
    @IBAction func editBtnAction(_ sender: NSButton) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose a .txt file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["txt"];
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                let path = result!.path
                print(path)
//                filename_field.stringValue = path
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
