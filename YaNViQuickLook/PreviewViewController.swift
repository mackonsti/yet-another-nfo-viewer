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

    // Bundled font defined in SharedCode.swift

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


    func preparePreviewOfFile(at url: URL) async throws {

        print("\nQuickLook extension loaded for:", url.lastPathComponent)

        // Ensure the bundled DOS font is available
        SharedCode.registerFonts()

        // Safely load the DOS font to avoid crashes
        struct QLError: Error { let message: String }

        // guard let nfoFont = NSFont(name: SharedCode.nfoFontName, size: SharedCode.nfoFontSize) else {
        //     throw QLError(message: "DOS font failed to load")
        // }

        // Fallback to the system's default monospace font instead
        let nfoFont = NSFont(name: SharedCode.nfoFontName, size: SharedCode.nfoFontSize)
            ?? NSFont.monospacedSystemFont(ofSize: SharedCode.nfoFontSize, weight: .regular)

        // Check NFO file size first (Limit set to 2 MB to avoid crashes)
        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
           let fileSize = attributes[.size] as? UInt64 {
            if fileSize > 2_097_152 {
                // Exiting process should display a generic "Preview not available" by macOS
                throw QLError(message: "File is too large to preview.")
            }
        }

        // Read NFO file contents using CP437 encoding
        let encoding = SharedCode.nfoEncoding()
        let nfoInput = try String(contentsOf: url, encoding: encoding)

        // Parse, trim and re-join into a single string for the NSTextView coming next
        let parsed = SharedCode.nfoTrimming(text: nfoInput)
        let nfoContents = parsed.lines.joined(separator: "\n")

        let originalLineCount = parsed.originalLineCount
        let finalLineCount = parsed.lines.count
        let longestLine = parsed.maxLineLength

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
                height: textHeight + SharedCode.nfoMargin
            )

            // Request QuickLook panel size
            self.preferredContentSize = NSSize(
                width: textWidth + SharedCode.nfoMargin,
                height: textHeight
            )

            print("Unicode characters count: file \(nfoContents.count) ≠ view: \(textView.string.count)")
        }
    }
}
