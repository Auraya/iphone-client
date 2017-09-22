//
//  EnrolYourVoiceTableViewCell.swift
//  ArmorVox
//
//  Created by Rob Dixon on 03/08/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import UIKit

class EnrolYourVoiceTableViewCell: UITableViewCell {

    @IBOutlet weak var microphoneWidthLayoutConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        microphoneWidthLayoutConstraint.constant = AppSettings.shared.iconWidthConstraintConstant
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
