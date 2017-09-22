//
//  TransferOptionsTableViewCell.swift
//  ArmorVox
//
//  Created by Rob Dixon on 31/07/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import UIKit

class TransferOptionsTableViewCell: UITableViewCell {

    // MARK: - Data
    
    var transferOptions: [TransferOption]! { // passed in
        didSet {
            if transferOptionsStackView.arrangedSubviews.count == 0 {
                for transferOption in transferOptions {
                    let width = AppSettings.shared.iconWidthConstraintConstant
                    let button = UIButton(frame: CGRect(x: 0, y: 0, width: width, height: width))
                    button.setImage(transferOption.image, for: .normal)
                    // Note: we're using buttons, to allow us to fade unimplemented options
                    button.isEnabled = transferOption.isImplemented
                    button.isUserInteractionEnabled = false
                    transferOptionsStackView.addArrangedSubview(button)
                }
            }
        }
    }
    
    // MARK: - UI
    
    @IBOutlet weak var transferOptionsStackView: UIStackView!
}
