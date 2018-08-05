//
//  ViewController.swift
//  MCLinkedLabel
//
//  Created by Baglan on 2018/8/4.
//  Copyright © 2018 Mobile Creators. All rights reserved.
//

import UIKit

class ViewController: UIViewController, MCLinkedLabelDelegate {

    @IBOutlet weak var label: MCLinkedLabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Process the label text as Markdown
        if let text = label.text {
            label.setMarkdownText(text)
        }
        
        // Set the link visual style
        label.linkUnderlineStyle = .styleNone
        
        // Assign self as deelgate
        label.delegate = self
    }
    
    // Process taps on linked text as a delegate
    func didTap(on fragment: MCLinkedLabel.LinkedFragment) {
        NSLog("[Tap]: \(fragment.url)")
    }
}

