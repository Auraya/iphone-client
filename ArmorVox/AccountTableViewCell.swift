//
//  AccountTableViewCell.swift
//  ArmorVox
//
//  Created by Rob Dixon on 31/07/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import UIKit

class AccountTableViewCell: UITableViewCell {

    // MARK: - Data
    
    var account: Account! { // passed in
        didSet {
            accountNumberLabel.text = "\(account.name) \(account.number)"
            accountCodeLabel.text = account.code
            availableBalanceLabel.text = account.availableBalance.currencyString
            currentBalanceLabel.text = account.currentBalance.currencyString
        }
    }
    
    // MARK: - UI
    
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var accountCodeLabel: UILabel!
    @IBOutlet weak var availableBalanceLabel: UILabel!
    @IBOutlet weak var currentBalanceLabel: UILabel!
}
