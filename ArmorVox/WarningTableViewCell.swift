//
//  WarningTableViewCell.swift
//  ArmorVox
//
//  Created by Rob Dixon on 03/08/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import UIKit

class WarningTableViewCell: UITableViewCell {
    
    // MARK: - Data
    var message: String! { // passed in
        didSet {
            warningLabel.text = message
            iconWidthLayoutConstraint.constant = AppSettings.shared.iconWidthConstraintConstant
        }
    }
    
    // MARK: - UI

    @IBOutlet weak var iconWidthLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var warningImageView: UIImageView!
    
}
