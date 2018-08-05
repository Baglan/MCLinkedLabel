//
//  MCLinkedTextRecognizer.swift
//  MCLinkedLabel
//
//  Created by Baglan on 2018/8/3.
//  Copyright © 2018 Mobile Creators. All rights reserved.
//

import Foundation

/// Recognizers for various types of links shouls adopt this protocol
protocol MCLinkedTextFragmentRecognizer: class {
    
    /// Rrecognizing function
    ///
    /// Should be ``static`` on the recognizer class
    ///
    /// - parameter text: String to be examied for possible linked fragments
    static func recognize(in text: String) -> [MCLinkedTextRecognizer.LinkedTextFragment]
}

class MCLinkedTextRecognizer {
    
    /// Zero-width space character; when replacing fragment with a suggested replacement text, it will be padded
    /// with these characters to keep the ranges the same
    static let zeroWidthSpace = "\u{200B}"
    
    /// Recognized text fragment
    struct LinkedTextFragment {
        
        /// Range of the fragment
        let range: Range<String.Index>
        
        /// Suggested replacement
        /// e.g "``Fred``" in place of "``[Fred](friends://fred)``"
        let replacement: String
        
        /// URL for the link
        let url: URL
    }
    
    /// Recognize linked fragments in the text
    ///
    /// - parameter text: String to be searched for fragments
    /// - parameter recognizers: An array of MCLinkedTextFragmentRecognizer classes (not objects) to be used for recognizing
    ///
    /// - returns: An array of recognized fragments
    class func recognize(in text: String, using recognizers: [MCLinkedTextFragmentRecognizer.Type]) -> [LinkedTextFragment] {
        var fragments = [LinkedTextFragment]()
        
        for recognizer in recognizers {
            fragments.append(contentsOf: recognizer.recognize(in: text))
        }
        
        return fragments
    }
    
    /// Replace recognized fragments using siggested replacement text
    ///
    /// This replacement will keep ranges intact by padding suggested text with ``zeroWidthSpace``.
    ///
    /// - warning: This function currently assumes that the replacement text will be shorter or the same length as the
    /// text to be replaced
    ///
    /// - parameter text: Text where relacements will be made
    /// - parameter fragments: An array of ``MCLinkedTextRecognizer.LinkedTextFragment``s, possibly, generated by the ``recognize(in:using:)`` function
    ///
    /// - returns: Text with replacements made
    class func replace(in text: String, fragments: [LinkedTextFragment]) -> String {
        var textWithReplacements = text
        
        for fragment in fragments {
            let lowerBound = fragment.range.lowerBound.encodedOffset
            let upperBound = fragment.range.upperBound.encodedOffset
            let length = upperBound - lowerBound
            let paddedReplacement = fragment.replacement.padding(toLength: length, withPad: zeroWidthSpace, startingAt: 0)
            
            textWithReplacements.replaceSubrange(fragment.range, with: paddedReplacement)
        }
        
        return textWithReplacements
    }
}

extension MCLinkedTextRecognizer {
    
    /// Recognizer for Markdown-style links
    ///
    /// E.g. "``[Fred](friend://fred)``"
    class MarkdownLinkRecognizer: MCLinkedTextFragmentRecognizer {
        static func recognize(in text: String) -> [LinkedTextFragment] {
            do {
                let regex = try NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\(([^\\)]+)\\)")
                return regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).map { (match) -> LinkedTextFragment in
                    
                    let anchorRange = match.range(at: 1)
                    let archor = String(text[Range(anchorRange, in: text)!])
                    
                    let urlRange = match.range(at: 2)
                    let urlString = String(text[Range(urlRange, in: text)!])
                    let url = URL(string: urlString)!
                    
                    return LinkedTextFragment(
                        range: Range(match.range, in: text)!,
                        replacement: archor,
                        url: url
                    )
                }
            } catch {
                NSLog("MarkdownLinkRecognizer: \(error)")
            }
            
            return [LinkedTextFragment]()
        }
    }
}


