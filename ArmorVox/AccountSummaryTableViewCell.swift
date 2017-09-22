//
//  AccountSummaryTableViewCell.swift
//  ArmorVox
//
//  Created by Rob Dixon on 31/07/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import UIKit

class AccountSummaryTableViewCell: UITableViewCell {

    // MARK: - Data
    
    var myAccounts: MyAccounts! { // passed in
        didSet {
            totalCreditBalanceLabel.text = myAccounts.totalCreditBalance.currencyString
        }
    }

    // MARK: - UI
    
    @IBOutlet weak var totalCreditBalanceLabel: UILabel!
}
