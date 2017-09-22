//
//  TransferToTableViewCell.swift
//  ArmorVox
//
//  Created by Rob Dixon on 31/07/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import UIKit

class TransferToTableViewCell: UITableViewCell {

    // MARK: - Data
    
    var account: Account! { // passed in
        didSet {
            accountNameLabel.text = account.name
            accountNumberLabel.text = "\(account.number)"
            accountCodeLabel.text = account.code
        }
    }
    
    // MARK: - UI
    
    @IBOutlet weak var accountNameLabel: UILabel!
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var accountCodeLabel: UILabel!
    
}
