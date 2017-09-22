//
//  UserSettingsViewController.swift
//  ArmorVox
//
//  Created by Rob Dixon on 04/08/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import UIKit

class UserSettingsViewController: UIViewController {
    
    // MARK: - UI
    
    @IBOutlet weak var nameTextField: UITextField! {
        didSet {
            nameTextField.delegate = self
        }
    }
    
    @IBOutlet weak var phoneNumberTextField: UITextField! {
        didSet {
            phoneNumberTextField.delegate = self
        }
    }
    @IBOutlet weak var phraseEnrolmentVariationSegmentedControl: UISegmentedControl! {
        didSet {
            // reduce font size, to fit iPhone SE
            let attributes = [NSFontAttributeName : UIFont.systemFont(ofSize: 9)]
            phraseEnrolmentVariationSegmentedControl.setTitleTextAttributes(attributes, for: .normal)
        }
    }
    
    
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        logger.log(.debug, "UserSettings: \(UserSettings.shared)")
        updateUI()
    }
    
    
    
    // MARK: - Action
    
    @IBAction func backgroundTapGesture(_ sender: UITapGestureRecognizer) {
        // dismiss the keyboard
        phoneNumberTextField.resignFirstResponder()
    }
    
    func updateUI() {
        nameTextField.placeholder = "Enter your name"
        nameTextField.text = UserSettings.shared.name
        
        phoneNumberTextField.placeholder = "Enter your phone number"
        phoneNumberTextField.text = UserSettings.shared.phoneNumber
        
        phraseEnrolmentVariationSegmentedControl.selectedSegmentIndex = UserSettings.shared.phraseEnrolmentVariation.rawValue
    }
    
    @IBAction func phraseEnrolmentVariationSegmentedControlChanged(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        if let variation = PhraseEnrolmentVariation(rawValue: index) {
            UserSettings.shared.phraseEnrolmentVariation = variation
            if UserSettings.shared.phraseEnrolmentStatus == .enrolled {
                deleteUser(speechItemType: .phrase) // unenrol
            }
        } else {
            logger.log(.error, "Invalid phraseEnrolmentVariation value: \(index)")
        }
    }
    
    func deleteUser(speechItemType: SpeechItemType) {
        guard let userID = UserSettings.shared.userID else {
            logger.log(.error, "Invalid userID!")
            return
        }
        ArmorVoxAPI.deleteUser(sessionID: ArmorVox.sessionID, userID: userID, type: speechItemType) { (response: ArmorVoxAPIResponse?) in
            // Note: there may be a delay before this callback...
            if let response = response {
                if let userID = response.userID, let condition = response.condition {
                    switch condition {
                    case .good:
                        logger.log(.debug, "Deleted \(speechItemType)")
                    case .not_enrolled:
                        logger.log(.debug, "Not Enrolled \(speechItemType)")
                    case .fail, .error:
                        logger.log(.debug, "\(response.extra ?? "fail") \(speechItemType)")
                    default:
                        logger.log(.error, "Unexpected condition: \(condition) (userID: \(userID), extra: \(response.extra ?? ""))")
                    }
                } else {
                    logger.log(.error, "Invalid response: \(response)")
                }
                self.updateUI()
            } else {
                logger.log(.error, "no response!")
            }
        }
    }
}



// MARK: - UITextFieldDelegate
extension UserSettingsViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // text field resigned first responder (user finished editing)
        switch textField {
        case nameTextField:
            UserSettings.shared.name = textField.text == "" ? nil : textField.text
        case phoneNumberTextField:
            // 2017-08-18 we're now leaving this as entered
            UserSettings.shared.phoneNumber = textField.text
        default:
            logger.log(.error, "Unexpected textField: \(textField)")
        }
        updateUI()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Called when user taps return button
        textField.resignFirstResponder() // dismiss the keyboard
        return true
    }
}





