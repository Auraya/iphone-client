//
//  SpeakTextTableViewCell.swift
//  ArmorVox
//
//  Created by Rob Dixon on 01/08/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import UIKit

class SpeakTextTableViewCell: UITableViewCell {

    // MARK: - Data
    var textToSpeak: String! { // passed in
        didSet {
            textToSpeakLabel.text = textToSpeak
            microphoneWidthLayoutConstraint.constant = AppSettings.shared.iconWidthConstraintConstant
            tickImageWidthLayoutConstraint.constant = AppSettings.shared.iconWidthConstraintConstant
        }
    }
    
    var done: Bool? { // passed in
        didSet {
            let tick = done ?? false
            tickImageView.image = tick ? UIImage(named: "tick") : nil
        }
    }
    
    // MARK: - UI
    
    @IBOutlet weak var microphoneWidthLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var tickImageWidthLayoutConstraint: NSLayoutConstraint!

    @IBOutlet weak var microphoneImageView: UIImageView!
    @IBOutlet weak var textToSpeakLabel: UILabel!
    @IBOutlet weak var tickImageView: UIImageView!
}
