//
//  PreviewViewController.swift
//  YaNViQuickLook
//
//  Created by mackonsti@outlook.com on 7/3/2026.
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
        guard let fontURL = Bundle(for: type(of: self)).url(forResource: nfoFontName, withExtension: "ttf") else {
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

        // Fallback encoding just in case DOS437 is not detected
        guard cfEncoding != kCFStringEncodingInvalidId else { return .isoLatin1 }
        let nsEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding)

        return String.Encoding(rawValue: nsEncoding)
    }


    func preparePreviewOfFile(at url: URL) async throws {

        print("\nQuickLook extension loaded for:", url.lastPathComponent)

        // Ensure the bundled DOS font is available
        registerFonts()

        // Safely load the DOS font to avoid crashes
        struct QLError: Error { let message: String }
        guard let nfoFont = NSFont(name: nfoFontName, size: nfoFontSize) else {
            throw QLError(message: "DOS font failed to load")
        }

        // Read NFO file contents using CP437 encoding
        let encoding = nfoEncoding()
        let nfoInput = try String(contentsOf: url, encoding: encoding)

        var lines = [String]()
        var longestLine = 0

        // Single-pass enumeration to normalize line endings and trim spaces (no Regex overhead)
        nfoInput.enumerateLines { line, _ in

            // Natively replace all tabs with 4 spaces before trimming
            // var trimmed = line.replacingOccurrences(of: "\t", with: "    ")[...]
            var trimmed = line[...]

            // Look at very last character and remove it if whitespace and save it back
            while trimmed.last?.isWhitespace == true { trimmed.removeLast() }
            lines.append(String(trimmed))

            if trimmed.count > longestLine { longestLine = trimmed.count }
        }

        // Remember the original number of lines before any trimming at the bottom
        let originalLineCount = lines.count

        // Remove all trailing blank lines at the bottom of document except one
        while lines.last?.isEmpty == true { lines.removeLast() }
        lines.append("")

        // Rejoin into a single string for the NSTextView coming next
        let nfoContents = lines.joined(separator: "\n")
        let finalLineCount = lines.count
        print("NFO count: \(originalLineCount) lines became \(finalLineCount) @ maxumum \(longestLine) chars" )

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

            // Find true line height used by AppKit
            let lineHeight: CGFloat
            if let layoutManager = textView.layoutManager {
                lineHeight = ceil(layoutManager.defaultLineHeight(for: nfoFont))
            } else {
                // Fallback: derive line height from the font's own metrics
                lineHeight = ceil(nfoFont.ascender + abs(nfoFont.descender) + nfoFont.leading)
            }

            // Monospaced glyph width
            let glyphWidth = ceil("M".size(withAttributes: [.font: nfoFont]).width)

            // Calculate ASCII art size
            let textWidth = CGFloat(longestLine) * glyphWidth
            let textHeight = CGFloat(finalLineCount) * lineHeight

            print("View metrics: \(textWidth) x \(textHeight) pixels")

            // Disable wrapping
            textView.textContainer?.containerSize = NSSize(
                width: textWidth,
                height: textHeight + nfoMargin
            )

            // Request QuickLook panel size
            self.preferredContentSize = NSSize(
                width: textWidth + nfoMargin,
                height: textHeight
            )

            print("Unicode characters count: file \(nfoContents.count) ≠ view: \(textView.string.count)")
        }
    }
}
