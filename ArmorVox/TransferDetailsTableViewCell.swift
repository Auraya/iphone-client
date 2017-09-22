//
//  TransferDetailsTableViewCell.swift
//  ArmorVox
//
//  Created by Rob Dixon on 31/07/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import UIKit

class TransferDetailsTableViewCell: UITableViewCell {

    // MARK: - Data
    var transferAmount: TransferAmount! { // passed in
        didSet {
            amountTextField.text = transferAmount.amount == 0 ? "" : transferAmount.amount.currencyString
            descriptionTextField.text = transferAmount.desc
        }
    }
    
    // MARK: - UI
    
    @IBOutlet weak var amountTextField: UITextField! {
        didSet {
            amountTextField.delegate = self
        }
    }
    @IBOutlet weak var descriptionTextField: UITextField! {
        didSet {
            descriptionTextField.delegate = self
        }
    }
}



extension TransferDetailsTableViewCell: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // text field resigned first responder (user finished editing)
        if textField == amountTextField { // user entered an amount
            if let amountString = amountTextField.text,
                let amount = Float(amountString) {
                transferAmount.amount = amount
            }
        }
        
        if textField == descriptionTextField { // user entered a description
            if let text = descriptionTextField.text {
                transferAmount.desc = text
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Called when user taps return button
        logger.log(.debug, "textfield: \(textField)")
        textField.resignFirstResponder() // dismiss the keyboard
        return true
    }
}
