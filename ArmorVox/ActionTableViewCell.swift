//
//  ActionTableViewCell.swift
//  ArmorVox
//
//  Created by Rob Dixon on 01/08/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import UIKit

class ActionTableViewCell: UITableViewCell {

    // MARK: - Data
    var title: String! { // passed in
        didSet {
            titleLabel.text = title
        }
    }
    
    // MARK: - UI

    @IBOutlet weak var titleLabel: UILabel!
}
