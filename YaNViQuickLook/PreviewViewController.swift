//
//  PreviewViewController.swift
//  YaNViQuickLook
//
//  Created by Konstantinos Giannakas on 7/3/26.
//

import Cocoa
import QuickLookUI
import CoreText

class PreviewViewController: NSViewController, QLPreviewingController {

    @IBOutlet var textView: NSTextView!

    // Set the bundled font (without the .ttf extension)
    let nfoFontName = "MorePerfectDOSVGA"
    let nfoFontSize: CGFloat = 16
    let nfoMargin: CGFloat = 20

    override var acceptsFirstResponder: Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the view properties
        textView.isEditable = false
        textView.isSelectable = false
        textView.isRichText = false

        textView.usesFontPanel = false
        textView.usesFindBar = false
        textView.allowsUndo = false

        textView.isHorizontallyResizable = true
        textView.isVerticallyResizable = true

        textView.textContainer?.lineBreakMode = .byClipping
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.heightTracksTextView = false

        textView.drawsBackground = true
        textView.backgroundColor = .white
        textView.textColor = .black

        textView.layoutManager?.usesFontLeading = false
        textView.layoutManager?.allowsNonContiguousLayout = true
        print("YaNVi QuickLook view did load")
    }


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


    func nfoEncoding() -> String.Encoding {

        let cfEncoding = CFStringConvertWindowsCodepageToEncoding(437)
        let nsEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding)

        return String.Encoding(rawValue: nsEncoding)
    }


    func preparePreviewOfFile(at url: URL) async throws {

        print("\nQuickLook extension loaded for:", url)

        // Ensure the bundled DOS font is available
        registerFonts()

        // Safely load the DOS font to avoid crashes
        guard let nfoFont = NSFont(name: nfoFontName, size: nfoFontSize) else {
            fatalError("DOS font failed to load")
        }

        // Read NFO file using CP437 encoding
        let encoding = nfoEncoding()
        var nfoContents = try String(contentsOf: url, encoding: encoding)

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

        // Split lines
        let lines = nfoContents.split(separator: "\n", omittingEmptySubsequences: false)
        print("NFO line count:", lines.count)

        // Determine metrics
        let longestLine = lines.map { $0.count }.max() ?? 0
        let numberOfLines = lines.count
        print("Longest line has: \(longestLine) chars")

        await MainActor.run {

            // Reset layout from previous preview
            textView.string = ""
            textView.layoutManager?.invalidateLayout(
                 forCharacterRange: NSRange(location: 0, length: 0),
                 actualCharacterRange: nil
            )

            // Configure text view
            textView.font = nfoFont
            textView.string = nfoContents

            // True line height used by AppKit
            let lineHeight = ceil(textView.layoutManager!.defaultLineHeight(for: nfoFont))

            // Monospaced glyph width
            let glyphWidth = ceil("M".size(withAttributes: [.font: nfoFont]).width)

            // Calculate ASCII art size
            let textWidth = CGFloat(longestLine) * glyphWidth
            let textHeight = CGFloat(numberOfLines) * lineHeight

            print("Metrics size: \(textWidth) x \(textHeight)")

            // Disable wrapping
            textView.textContainer?.containerSize = NSSize(
                width: textWidth,
                height: textHeight
            )

            // Request QuickLook panel size
            self.preferredContentSize = NSSize(
                width: textWidth + nfoMargin,
                height: textHeight
            )
        }

        print("Unicode characters count: file \(nfoContents.count) vs. view: \(textView.string.count)")
    }
}
