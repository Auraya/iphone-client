//
//  ConfirmationTableViewCell.swift
//  ArmorVox
//
//  Created by Rob Dixon on 01/08/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import UIKit

class ConfirmationTableViewCell: UITableViewCell {

    // MARK: - Data
    var transfer: Transfer! { // passed in
        didSet {
            amountLabel.text = transfer.transferAmount.amount.currencyString
            fromLabel.text = transfer.fromAccount.name
            toLabel.text = transfer.toAccount.name
            whenLabel.text = transfer.payWhen.description
            descriptionLabel.text = transfer.transferAmount.desc
        }
    }
    
    // MARK: - UI
    
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var whenLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
}
