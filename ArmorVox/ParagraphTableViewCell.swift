//
//  ParagraphTableViewCell.swift
//  ArmorVox
//
//  Created by Rob Dixon on 01/08/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import UIKit

class ParagraphTableViewCell: UITableViewCell {

    // MARK: - Data
    var paragraph: String! { // passed in
        didSet {
            paragraphLabel.text = paragraph
        }
    }
    
    // MARK: - UI
    
    @IBOutlet weak var paragraphLabel: UILabel!
}
