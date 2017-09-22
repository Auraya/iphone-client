//
//  TransferPayWhenTableViewCell.swift
//  ArmorVox
//
//  Created by Rob Dixon on 01/08/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import UIKit

class TransferPayWhenTableViewCell: UITableViewCell {
    
    // MARK: - Data
    var transferPayWhen: TransferPayWhen! { // passed in
        didSet {
            payWhenLabel.text = transferPayWhen.description
        }
    }
    
    // MARK: - UI

    @IBOutlet weak var payWhenLabel: UILabel!
    
}
