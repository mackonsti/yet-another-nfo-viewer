//
//  AppDelegate.swift
//  YaNVi
//
//  Created by Konstantinos Giannakas on 06/03/2026.
//

import Cocoa
import UniformTypeIdentifiers

/*
 ---------------------------------------------------------------------------
 Yet Another NFO Viewer (Swift version)

 This file replaces the original Objective-C AppDelegate implementation.

 Key differences from the original code:

 - Swift ARC replaces manual retain/release memory management
 - NSError patterns replaced by Swift error handling
 - NSString → Swift String
 - CFString encoding conversion simplified
 - Objective-C selectors replaced by Swift methods

 Behaviour of the application remains identical.
 ---------------------------------------------------------------------------
*/

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    /*
     -----------------------------------------------------------------------
     These outlets are connected to the interface defined in MainMenu.xib.
     They correspond exactly to the original Objective-C IBOutlets.

     nfoWindow  -> main display window
     nfoTextView -> NSTextView used to render NFO ASCII art
     -----------------------------------------------------------------------
     */

    @IBOutlet weak var nfoWindow: NSWindow!
    @IBOutlet var nfoTextView: NSTextView!

    @IBAction func openDocument(_ sender: Any?) {
        print("Menu Open selected")
        openNFOFile()
    }

    @IBAction func printDocument(_ sender: Any?) {
        print("Menu Print selected")

        // Printing defaults of a temporary session
        let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo

        // Reduce margins (in points) for wide ASCII
        printInfo.leftMargin = 50
        printInfo.rightMargin = 50
        printInfo.topMargin = 50
        printInfo.bottomMargin = 50

        // Pagination
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .automatic
        printInfo.isHorizontallyCentered = true
        printInfo.isVerticallyCentered = false

        // Landscape helps with wide NFOs
        printInfo.orientation = .portrait

        // Set the available printing options
        let operation = NSPrintOperation(view: nfoTextView, printInfo: printInfo)
        operation.printPanel.options = [
            .showsCopies,
            .showsPageRange,
            .showsPaperSize,
            .showsOrientation,
            .showsScaling,
            .showsPreview
        ]
        operation.run()
    }

    // Set the bundled font (without the .ttf extension)
    let nfoFontName = "MorePerfectDOSVGA"
    let nfoFontSize: CGFloat = 16

    // Track whether the app was launched by opening a file
    var hasDroppedFile = false

    // Window padding constants (same values as original project)
    let horizontalWindowPadding: CGFloat = 20
    let verticalWindowPadding: CGFloat = 40

    // Create native Message alert
    func showFatalError(_ message: String, info: String? = nil) -> Never {

        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = message
        alert.informativeText = info ?? ""
        alert.addButton(withTitle: "Quit")

        alert.runModal()
        NSApp.terminate(self)
        fatalError("Application was terminated")
    }


    // --------------------------------------------------------------------
    // SECTION 1: - Font Registration
    // --------------------------------------------------------------------

    /*
     NFO files rely on a DOS-style fixed-width font for correct rendering
     of ASCII / ANSI art. The fonts bundled with YaNVi are:

        • MorePerfectDOSVGA
        • ProFontWindows

     Modern versions of macOS do NOT automatically register fonts that are
     included inside the application bundle. If we do nothing, a call like:

        NSFont(name:size:)

     would return nil because the system does not yet know about the font.

     Therefore we manually register the fonts at application startup using
     CoreText's CTFontManagerRegisterFontsForURL().

     This function:

     1. Looks up each font inside the application bundle
     2. Registers it for the current process
     3. Prints debug information to the console
    */

    func registerFonts() {

        // If font already exists in system (PostScript name) skip registration
        if NSFont(name: nfoFontName, size: nfoFontSize) != nil {
            print("Font already available:", nfoFontName)
            return
        }

        // Locate the font file inside the application bundle
        guard let fontURL = Bundle.main.url(forResource: nfoFontName, withExtension: "ttf") else {
            print("Font not found in bundle:", nfoFontName)
            return
        }

        var error: Unmanaged<CFError>?

        // Register the font with the CoreText font manager
        if CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
            print("Registered font:", nfoFontName)
        } else {
            print("Font registration failed:", error?.takeRetainedValue().localizedDescription ?? "unknown")
        }
    }


    // --------------------------------------------------------------------
    // SECTION 2: - File Encoding
    // --------------------------------------------------------------------

    /*
     NFO files are traditionally encoded using DOS Codepage 437.
     Swift provides a built-in encoding for this: String.Encoding.dosCP437
     */

    func nfoEncoding() -> String.Encoding {

        let cfEncoding = CFStringConvertWindowsCodepageToEncoding(437)
        let nsEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding)

        return String.Encoding(rawValue: nsEncoding)
    }


    // --------------------------------------------------------------------
    // SECTION 3: - File Open Dialog
    // --------------------------------------------------------------------

    /*
     Opens the file selection dialog allowing the user to pick an NFO file.
     */

    func openNFOFile() {

        print("Opening file dialog")

        let openPanel = NSOpenPanel()

        openPanel.allowedContentTypes = [
            UTType(filenameExtension: "nfo")!,
            UTType(filenameExtension: "asc")!,
            UTType(filenameExtension: "diz")!
        ]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseFiles = true
        openPanel.resolvesAliases = true
        openPanel.message = NSLocalizedString("OPEN_SELECT_FILE", comment: "")

        if openPanel.runModal() == .OK, let url = openPanel.url {

            // Add file to "Open Recent"
            NSDocumentController.shared.noteNewRecentDocumentURL(url)
            showNFOContentsWindow(url)

        } else {

            print("No NFO file selected")
            NSApp.terminate(self)
        }
    }


    // --------------------------------------------------------------------
    // SECTION 4: - Display NFO Window
    // --------------------------------------------------------------------

    /*
     Reads the file contents and displays them inside the NSTextView.
     */

    func showNFOContentsWindow(_ url: URL) {

        print("Imported \(url)")

        // Read file using DOS codepage 437
        guard var nfoContents = try? String(contentsOf: url, encoding: nfoEncoding()) else {
            print("Unable to read file for some reason")
            return
        }

        // Convert LF or CR to "\n"
        nfoContents = nfoContents
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        // Remove trailing spaces or tabs on every line
        nfoContents = nfoContents.replacingOccurrences(
            of: #"(?m)[ \t]+$"#,
            with: "",
            options: .regularExpression
        )

        // Remove trailing blank lines
        nfoContents = nfoContents.replacingOccurrences(
            of: #"\n+$"#,
            with: "",
            options: .regularExpression
        )

        // Safely load the DOS font to avoid crashes
        guard let nfoFont = NSFont(name: nfoFontName, size: nfoFontSize) else {
            showFatalError(
                "Required DOS font could not be loaded.",
                info: "YaNVi requires the bundled DOS font to display NFO files correctly."

            // Termination error is sent by the above alert itself
            // fatalError("DOS font failed to load")
            )
        }

        /*
         Reset the text system completely.
         This avoids cached layout from previous NFO files
         affecting the next one (which caused cropping).
         */

        nfoTextView.string = ""
        nfoTextView.layoutManager?.invalidateLayout(forCharacterRange: NSRange(location: 0, length: 0), actualCharacterRange: nil)

        // Configure text view
        nfoTextView.font = nfoFont
        nfoTextView.string = nfoContents

        /*
         Ensure pixel-perfect ASCII rendering.

         CP437 NFO artwork assumes that every character occupies
         an identical integer glyph advance (as in DOS text mode).
         Modern macOS text layout may use fractional glyph metrics
         which can introduce subtle spacing differences.
         By disabling font smoothing for this text view we force
         the layout system to snap glyph advances to integer values,
         producing perfectly aligned ASCII art.
        */

        nfoTextView.usesFontPanel = false
        nfoTextView.layoutManager?.usesFontLeading = false

        /*
         Disable ligatures and ensure fixed glyph rendering.
         ASCII NFO artwork assumes that each character is rendered
         independently with a fixed advance width. Ligatures (where
         multiple characters combine into a single glyph) would break
         alignment, so we explicitly disable them.
        */

        nfoTextView.textStorage?.addAttribute(
            .ligature,
            value: 0,
            range: NSRange(location: 0, length: nfoTextView.string.count)
        )

        // Disable wrapping (important for NFO)
        nfoTextView.isHorizontallyResizable = true
        nfoTextView.isVerticallyResizable = true

        // NFO viewer basic behaviour
        nfoTextView.isEditable = false
        nfoTextView.isSelectable = true
        nfoTextView.allowsUndo = false

        nfoTextView.isContinuousSpellCheckingEnabled = false
        nfoTextView.isGrammarCheckingEnabled = false

        nfoTextView.textContainer?.widthTracksTextView = false
        nfoTextView.textContainer?.heightTracksTextView = false
        nfoTextView.textContainer?.lineBreakMode = .byClipping
        nfoTextView.textContainer?.lineFragmentPadding = 0
        nfoTextView.textContainerInset = .zero

        nfoTextView.backgroundColor = .white
        nfoTextView.textColor = .black

        // Calculate window size required for the ASCII art
        sizeForStringDrawing(nfoContents, font: nfoFont)

        // Window configuration
        // if !nfoWindow.isVisible { nfoWindow.center() }
        nfoWindow.title = url.lastPathComponent
        nfoWindow.showsResizeIndicator = false
        nfoWindow.isMovableByWindowBackground = true

        nfoWindow.standardWindowButton(.miniaturizeButton)?.isHidden = true
        nfoWindow.standardWindowButton(.zoomButton)?.isHidden = true

        // Now show the window!
        nfoWindow.makeKeyAndOrderFront(self)
    }


    // --------------------------------------------------------------------
    // SECTION 5: - Dynamic Window Sizing
    // --------------------------------------------------------------------

    /*
     Calculates the window size deterministically using
     font metrics (line count × glyph width).

     This avoids the rounding errors that occur when measuring
     rendered text via NSLayoutManager.
     */

    func sizeForStringDrawing(_ text: String, font: NSFont) {

        // Avoid a theoretical crash if macOS reports no main screen
        guard let visibleScreen = NSScreen.main?.visibleFrame else { return }

        // Split lines
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        print("NFO line count:", lines.count)

        // Longest line
        let longestLineLength = lines.map { $0.count }.max() ?? 0

        // True line height used by AppKit
        let lineHeight = ceil(NSLayoutManager().defaultLineHeight(for: font))

        // Monospaced glyph width
        let glyphWidth = ceil("M".size(withAttributes: [.font: font]).width)

        let textWidth = CGFloat(longestLineLength) * glyphWidth
        let textHeight = CGFloat(lines.count) * lineHeight

        print("Metrics size: \(textWidth) x \(textHeight)")

        var windowWidth = textWidth
        var windowHeight = textHeight

        // Detect vertical scrollbar and add padding
        if textHeight > visibleScreen.height - verticalWindowPadding {
            let scrollbarWidth = NSScroller.scrollerWidth(
                for: .regular,
                scrollerStyle: .legacy
            )
            windowWidth += scrollbarWidth + 2
        }

        // Screen limits scenarios
        if windowWidth > visibleScreen.width {
            windowWidth = visibleScreen.width - horizontalWindowPadding
        }

        if windowHeight > visibleScreen.height {
            windowHeight = visibleScreen.height - verticalWindowPadding
        }

        nfoTextView.textContainer?.containerSize = NSSize(
            width: textWidth,
            height: textHeight
        )

        if let container = nfoTextView.textContainer {
            nfoTextView.layoutManager?.ensureLayout(for: container)
        }

        let windowSize = NSSize(width: ceil(windowWidth), height: ceil(windowHeight))

        nfoWindow.setContentSize(windowSize)
        nfoWindow.center();
        nfoWindow.minSize = NSSize(width: windowWidth, height: windowHeight / 2)
        nfoWindow.maxSize = NSSize(width: windowWidth, height: CGFloat.greatestFiniteMagnitude)
    }


    // --------------------------------------------------------------------
    // SECTION 6: - Application Lifecycle
    // --------------------------------------------------------------------

    func applicationWillFinishLaunching(_ notification: Notification) {
        print("Application will finish launching")
        hasDroppedFile = false
        registerFonts()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Application finished launching")
        print("Current system language or region:", Locale.preferredLanguages)
        print("Bundle preferred localizations:", Bundle.main.preferredLocalizations)
        print("Bundle localizations available:", Bundle.main.localizations)
        print("Development localization:", Bundle.main.developmentLocalization ?? "none")
    }

    // Called when the application is launched without a document
    // We present the Open dialog instead of creating an empty window
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {

        if !hasDroppedFile {
            openNFOFile()
        }
        return false
    }

    //Called when user opens a file via Finder or drags-and-drops it
    func application(_ application: NSApplication, open urls: [URL]) {

        hasDroppedFile = true

        for url in urls {
            print("Received \(url)")
            showNFOContentsWindow(url)

            // Add file to "Open Recent"
            NSDocumentController.shared.noteNewRecentDocumentURL(url)
        }
    }

    // Quit application after window closes or if fatal error occurs
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {

        print("Application terminating after window close")
        return true
    }
}
