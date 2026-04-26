//
//  EscapeWindow.swift
//  YaNVi
//
//  Created by mackonsti@outlook.com on 06/03/2026.
//

import Cocoa

/*
 ---------------------------------------------------------------------------
 Custom NSWindow subclass.

 Intercepts the Escape key and terminates the application.
 This replicates the behavior common in many small utility viewers.
 ---------------------------------------------------------------------------
*/

class EscapeWindow: NSWindow {

    override func cancelOperation(_ sender: Any?) {

        // Called automatically when Escape is pressed
        self.close()
    }
}
