//
//  MCLinkedLabel.swift
//  MCLinkedLabel
//
//  Created by Baglan on 2018/8/3.
//  Copyright © 2018 Mobile Creators. All rights reserved.
//

import Foundation
import UIKit

/// Delegate is informed about taps on linked text
protocol MCLinkedLabelDelegate: class {
    
    /// Receive the link information when an active fragment is tapped
    /// - parameter fragment: Information about the related link
    func didTap(on fragment: MCLinkedLabel.LinkedFragment)
}

/// Label for displaying linked text
@IBDesignable class MCLinkedLabel: UIView {
    
    /// Delegate to receive a callbacks when links are tapped
    weak var delegate: MCLinkedLabelDelegate?
    
    /// Label text, (see also ``linkedFragments``)
    @IBInspectable var text: String? { didSet { update() } }
    
    /// Information about a link in the text
    struct LinkedFragment {
        
        /// Range of the active area in the text
        let range: Range<String.Index>
        
        /// URL related to it
        let url: URL
    }
    
    /// Linked fragments in the text
    var linkedFragments = [LinkedFragment]() { didSet { update() } }
    
    @IBInspectable var font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize) { didSet { update() } }
    @IBInspectable var textColor: UIColor = UIColor.darkText { didSet { update() } }
    @IBInspectable var linkColor: UIColor = UIColor.blue { didSet { update() } }
    @IBInspectable var linkUnderlineStyle: NSUnderlineStyle = .styleSingle { didSet { update() } }
    
    override var bounds: CGRect { didSet { update() } }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    // MARK: - Setting up the control
    
    internal let layoutManager = NSLayoutManager()
    internal let textContainer = NSTextContainer(size: CGSize.zero)
    internal let textStorage = NSTextStorage()
    
    internal func setup() {
        layoutManager.addTextContainer(textContainer)
        textContainer.lineFragmentPadding = 0
        textStorage.addLayoutManager(layoutManager)
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap(recognizer:))))
    }
    
    // MARK: - Updating the control
    
    internal func update() {
        guard let text = text else { return }
        
        let attributedString = NSMutableAttributedString(
            string: text,
            attributes: [
                NSAttributedStringKey.font: font,
                NSAttributedStringKey.foregroundColor: textColor,
                ]
        )
        
        for fragment in linkedFragments {
            attributedString.addAttributes(
                [
                    NSAttributedStringKey.foregroundColor: linkColor,
                    NSAttributedStringKey.underlineStyle: linkUnderlineStyle.rawValue,
                    // If URL is set, on the range, the text will be highlighted with
                    // default color and style, not sure how to override it
                    // NSAttributedStringKey.link: fragment.url,
                ],
                range: NSRange(fragment.range, in: text)
            )
        }
        
        textStorage.setAttributedString(attributedString)
        
        textContainer.size = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        
        setNeedsDisplay()
        invalidateIntrinsicContentSize()
    }
    
    // MARK: - Process taps
    
    @objc internal func tap(recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {

            let indexOfCharacter = layoutManager.characterIndex(
                for: recognizer.location(in: self),
                in: textContainer,
                fractionOfDistanceBetweenInsertionPoints: nil
            )
            
            let characterIndex = String.Index(encodedOffset: indexOfCharacter)
            
            for fragment in linkedFragments {
                if fragment.range.contains(characterIndex) {
                    delegate?.didTap(on: fragment)
                }
            }
        }
    }
    
    // MARK: - Drawing
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        textStorage.draw(
            with: bounds,
            options: [.usesLineFragmentOrigin],
            context: nil
        )
    }
    
    // MARK: - Intrinsic content size
    
    override var intrinsicContentSize: CGSize {
        let boundingRect = textStorage.boundingRect(
            with: CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin],
            context: nil
        )
        return CGSize(
            width: ceil(boundingRect.width),
            height: ceil(boundingRect.height)
        )
    }
    
    // MARK: - IB
    
    override func prepareForInterfaceBuilder() {
        let sampleText = text ?? "Hello [Fred](friend://fred), [Annie](friend://annie), [Boris](friend://boris), nice to see you all!"
        
        let fragments = MCLinkedTextRecognizer.recognize(
            in: sampleText,
            using: [MCLinkedTextRecognizer.MarkdownLinkRecognizer.self]
        )
        let replacementText = MCLinkedTextRecognizer.replace(in: sampleText, fragments: fragments)
        text = replacementText
        linkedFragments = fragments.map({ (fragment) -> LinkedFragment in
            return LinkedFragment(range: fragment.range, url: fragment.url)
        })
    }
}

extension MCLinkedLabel {
    
    /// A convenience method to process Markdown-style links
    ///
    /// - warning: Requires presence of ``MCLinkedTextRecognizer``
    ///
    /// - parameter markdown: Text with MArkdown-style links
    func setMarkdownText(_ markdown: String) {
        let fragments = MCLinkedTextRecognizer.recognize(
            in: markdown,
            using: [MCLinkedTextRecognizer.MarkdownLinkRecognizer.self]
        )
        let replacementText = MCLinkedTextRecognizer.replace(in: markdown, fragments: fragments)
        text = replacementText
        linkedFragments = fragments.map({ (fragment) -> MCLinkedLabel.LinkedFragment in
            return MCLinkedLabel.LinkedFragment(range: fragment.range, url: fragment.url)
        })
    }
}
