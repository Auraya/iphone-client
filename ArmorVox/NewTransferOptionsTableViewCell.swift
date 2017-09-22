//
//  NewTransferOptionsTableViewCell.swift
//  ArmorVox
//
//  Created by Rob Dixon on 17/08/2017.
//  Copyright © 2017 notyou. All rights reserved.
//

import UIKit

class NewTransferOptionsTableViewCell: UITableViewCell {
    
    // UI
    @IBOutlet weak var transferButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var payAnyoneButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var payBillsButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var mobileButtonHeight: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        transferButtonHeight.constant = AppSettings.shared.iconWidthConstraintConstant
        payAnyoneButtonHeight.constant = AppSettings.shared.iconWidthConstraintConstant
        payBillsButtonHeight.constant = AppSettings.shared.iconWidthConstraintConstant
        mobileButtonHeight.constant = AppSettings.shared.iconWidthConstraintConstant
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
