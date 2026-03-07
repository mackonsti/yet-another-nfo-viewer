import Cocoa

// --------------------------------------------------------------------
// MARK: - Escape Window
// --------------------------------------------------------------------

/*
 Custom NSWindow subclass.

 Intercepts the Escape key and terminates the application.
 This replicates the behavior common in many small utility viewers.
*/

class EscapeWindow: NSWindow {

    override func cancelOperation(_ sender: Any?) {

        // Called automatically when Escape is pressed
        self.close()
    }
}
