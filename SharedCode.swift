//
//  Shared.swift
//  YaNVi
//
//  Created by mackonsti@outlook.com on 06/06/2026.
//

import Cocoa

struct SharedCode {
    static let nfoFontName: String = "MorePerfectDOSVGA"
    static let nfoFontSize: CGFloat = 16
    static let nfoMargin: CGFloat = 20

    // --------------------------------------------------------------------
    // FUNCTION 1: - Font Registration
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

    static func registerFonts() {

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
    // FUNCTION 2: - File Encoding
    // --------------------------------------------------------------------

    /*
     NFO files are traditionally encoded using DOS Codepage 437.
     Swift provides a built-in encoding for this: String.Encoding.dosCP437
     */

    static func nfoEncoding() -> String.Encoding {

        let cfEncoding = CFStringConvertWindowsCodepageToEncoding(437)

        // Fallback encoding just in case CP437 is not detected
        guard cfEncoding != kCFStringEncodingInvalidId else { return .isoLatin1 }

        // let nsEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding)
        // return String.Encoding(rawValue: nsEncoding)
        return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
    }

    // --------------------------------------------------------------------
    // FUNCTION 3: - Text Parsing & Trimming
    // --------------------------------------------------------------------

    /*
     Parses the raw NFO string data and prepares it for monospace rendering.

     This function:
     1. Normalizes all line endings via enumeration.
     2. Trims trailing horizontal whitespace from every line.
     3. Removes excess vertical blank lines at the bottom of the document.
     4. Calculates the maximum line width required for UI sizing.

     Returns the cleaned array of lines, the maximum character width,
     the original line count, and a boolean indicating if any
     horizontal whitespace trimming actually occurred.
     */

    static func nfoTrimming(text: String) -> (lines: [String], maxLineLength: Int, originalLineCount: Int, didTrimWhitespace: Bool) {

        var lines = [String]()
        var longestLine = 0
        var didTrimWhitespace = false

        // Single-pass enumeration to normalize line endings and trim spaces (no Regex overhead)
        text.enumerateLines { line, _ in

            // Natively replace all tabs with 4 spaces before trimming
            // var trimmed = line.replacingOccurrences(of: "\t", with: "    ")[...]
            var trimmed = line[...]

            // Look at very last character and remove it if whitespace and save it back
            while trimmed.last?.isWhitespace == true {
                trimmed.removeLast()
                didTrimWhitespace = true
            }

            lines.append(String(trimmed))
            if trimmed.count > longestLine { longestLine = trimmed.count }
        }

        // Remember the original number of lines before any trimming at the bottom
        let originalLineCount = lines.count

        // Remove all trailing blank lines at the bottom of document except one
        while lines.last?.isEmpty == true { lines.removeLast() }
        lines.append("")

        // Return all four pieces of data
        return (lines, longestLine, originalLineCount, didTrimWhitespace)
    }
}
