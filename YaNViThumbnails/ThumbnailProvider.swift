//
//  ThumbnailProvider.swift
//  YaNViThumbnails
//
//  Created by mackonsti@outlook.com on 25/4/2026.
//

import QuickLookThumbnailing
import AppKit
import CoreText

class ThumbnailProvider: QLThumbnailProvider {

    // Bundled font defined in SharedCode.swift

    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {

        // Register bundled font using shared code
        SharedCode.registerFonts()

        // Check if the font actually loaded, otherwise quit thumbnail renderer
        if NSFont(name: SharedCode.nfoFontName, size: SharedCode.nfoFontSize) == nil {
            handler(nil, nil)
            return
        }

        // Get requested thumbnail size
        let maxThumSize = request.maximumSize

        // Calculate a document-like aspect ratio (A4, US Letter or US Legal):
        // By providing a thumbnail with a document aspect ratio, we signal to macOS
        // that this is a "Document" type, which helps trigger the "Page" decoration
        //
        // let A4Ratio: CGFloat = 1.0 / 1.414
        // let legalRatio: CGFloat = 8.5 / 14.0
        let letterRatio: CGFloat = 8.5 / 11.0

        var width = maxThumSize.width
        var height = width / letterRatio

        // Ensure the calculated dimensions stay within the system's requested maximum size
        if height > maxThumSize.height {
            height = maxThumSize.height
            width = height * letterRatio
        }

        // Define the thumbnail rendered image size
        let size = CGSize(width: width, height: height)

        // Create the reply object with the defined document-shaped size where
        // we use the context-based initializer to draw our text content manually
        let reply = QLThumbnailReply(contextSize: size) { context in

            // Fill background with paper white (base icon canvas)
            context.setFillColor(NSColor.white.cgColor)
            context.fill(CGRect(origin: .zero, size: size))

            // Define drawing rectangle (use ~99% of width and height)
            let insetX = size.width * 0.005
            let insetY = size.height * 0.005
            let drawRect = CGRect(x: insetX, y: insetY, width: size.width * 0.99, height: size.height * 0.99)

            // Check NFO file size first (Limit set to 2 MB to avoid crashes)
            if let attributes = try? FileManager.default.attributesOfItem(atPath: request.fileURL.path),
               let fileSize = attributes[.size] as? UInt64 {
                if fileSize > 2_097_152 {
                    // Exit process and quit thumbnail renderer
                    return false
                }
            }

            // Read NFO file contents using CP437 encoding
            let text: String
            do {
                text = try String(contentsOf: request.fileURL, encoding: SharedCode.nfoEncoding())
            } catch {
                return false  // Return false so QuickLook falls back to the default file icon
            }

            var lines = [String]()
            var maxLineLength = 1  // Use 1 to prevent divide-by-zero crashes on empty files

            // Single-pass enumeration to normalize line endings and trim spaces (no Regex overhead)
            text.enumerateLines { line, stop in

                // Natively replace all tabs with 4 spaces before trimming
                // var trimmed = line.replacingOccurrences(of: "\t", with: "    ")[...]
                var trimmed = line[...]

                // Look at very last character and remove it if whitespace and save it back
                while trimmed.last?.isWhitespace == true { trimmed.removeLast() }
                lines.append(String(trimmed))

                if trimmed.count > maxLineLength { maxLineLength = trimmed.count }

                // Generous limit: Ensure we have enough lines to reach the bottom
                // of the Finder icon even if the text is zoomed out microscopically
                if lines.count >= 500 { stop = true }
            }

            // Remove all trailing blank lines at the bottom of document
            while lines.last?.isEmpty == true { lines.removeLast() }
            if lines.isEmpty { return false }

            // Use the file's natural width to dynamically stretch to the edges
            let maxChars = maxLineLength

            // Provide font name and size to draw sample
            let baseFont = CTFontCreateWithName(SharedCode.nfoFontName as CFString, SharedCode.nfoFontSize, nil)

            // Measure one character width (M or W)
            let sample = NSAttributedString(string: "M", attributes: [.font: baseFont])
            let sampleLine = CTLineCreateWithAttributedString(sample)
            let charWidth = CGFloat(CTLineGetTypographicBounds(sampleLine, nil, nil, nil))

            // Scale font so the full width is used
            let scale = drawRect.width / (CGFloat(maxChars) * charWidth)
            let finalFontSize = SharedCode.nfoFontSize * scale
            let ctFont = CTFontCreateWithName(SharedCode.nfoFontName as CFString, finalFontSize, nil)

            // Compute line height (tight, no leading)
            let ascent = CTFontGetAscent(ctFont)
            let descent = CTFontGetDescent(ctFont)

            // Empirical correction factor for DOS font vertical metrics to remove banding
            let lineHeight = (ascent + descent) * 0.70

            // Compute how many lines fit vertically
            let maxLines = Int(drawRect.height / lineHeight)

            // Prepare CoreText attributes
            let attributes: [NSAttributedString.Key: Any] = [
                .font: ctFont,
                .foregroundColor: NSColor.black.cgColor
            ]

            // Translate context to drawing origin
            context.saveGState()
            context.translateBy(x: drawRect.origin.x, y: drawRect.origin.y)

            // Draw lines top-down (truncate vertically)
            var y = drawRect.height - lineHeight

            for i in 0..<min(maxLines, lines.count) {

                // Create attributed string per line
                let attrString = NSAttributedString(string: lines[i], attributes: attributes)
                let ctLine = CTLineCreateWithAttributedString(attrString)

                // Snap Y to integer to reduce banding and blurry sub-pixel rendering
                context.textPosition = CGPoint(x: 0, y: round(y))
                CTLineDraw(ctLine, context)

                y -= lineHeight
                if y < 0 { break }
            }

            // Restore context and return
            context.restoreGState()
            return true
        }

        // Return reply with the render
        handler(reply, nil)
    }
}
