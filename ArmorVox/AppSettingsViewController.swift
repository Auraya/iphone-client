//
//  AppSettingsViewController.swift
//  ArmorVox
//
//  Created by Rob Dixon on 04/08/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import UIKit

class AppSettingsViewController: UIViewController {
    
    // MARK: - UI
    
    @IBOutlet weak var verificationOptionSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var deleteUserLabel: UILabel!
    @IBOutlet weak var deleteUserButton: UIButton!
    
    fileprivate var spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge) // show retrieval activity
    
    // MARK: - Data
    
    fileprivate var deletedByPhraseString = "" {
        didSet {
            deleteUserLabel.text = "\(deletedByPhraseString) \n\(deletedByTextPromptedString)"
        }
    }
    fileprivate var deletedByTextPromptedString = "" {
        didSet {
            deleteUserLabel.text = "\(deletedByPhraseString) \n\(deletedByTextPromptedString)"
        }
    }
    
    
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // add the activity spinner
        spinner.addTo(view)
        deleteUserLabel.text = ""
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        logger.log(.debug, "AppSettings: \(AppSettings.shared)")
        updateUI()
    }
    
    override func viewDidLayoutSubviews() {
        // autolayout has happened...
        super.viewDidLayoutSubviews()
        spinner.positionAtCenter(view) // position spinner at center of (some) view
    }
    
    
    
    // MARK: - Action
    
    func updateUI() {
        verificationOptionSegmentedControl.selectedSegmentIndex = AppSettings.shared.verificationType.rawValue
        deleteUserButton.isEnabled = false
        var enrolledString = ""
        if UserSettings.shared.phraseEnrolmentStatus == .enrolled {
            deleteUserButton.isEnabled = true
            enrolledString.append("Enrolled (phrase) ")
        }
        if UserSettings.shared.numbersEnrolmentStatus == .enrolled {
            deleteUserButton.isEnabled = true
            enrolledString.append("Enrolled (numbers) ")
        }
        deleteUserLabel.text = enrolledString
    }
    
    @IBAction func verificationOptionSegmentedControlChanged(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        if let type = VerificationType(rawValue: index) {
            AppSettings.shared.verificationType = type
        } else {
            logger.log(.error, "Invalid VerificationType value: \(index)")
        }
    }
    
    @IBAction func deleteUserButtonPress(_ sender: UIButton) {
        deleteUser(speechItemType: .phrase) // .phrase or .textPrompted
        deleteUser(speechItemType: .textPrompted) // .phrase or .textPrompted
        UserSettings.shared.overallStatus = .readyToEnrol
    }
    
    func setDeleteUserResponse(response: String, forSpeechItemType speechItemType: SpeechItemType) {
        switch speechItemType {
        case .phrase:
            deletedByPhraseString = "\(speechItemType): \(response)"
        case .textPrompted:
            deletedByTextPromptedString = "\(speechItemType): \(response)"
        default:
            break
        }
    }
    
    
    
    // MARK: - Methods
    
    func deleteUser(speechItemType: SpeechItemType) {
        guard let userID = UserSettings.shared.userID else {
            logger.log(.error, "Invalid userID!")
            return
        }
        spinner.startAnimating() // activity started
        setDeleteUserResponse(response: "Deleting...", forSpeechItemType: speechItemType)
        ArmorVoxAPI.deleteUser(sessionID: ArmorVox.sessionID, userID: userID, type: speechItemType) { (response: ArmorVoxAPIResponse?) in
            // Note: there may be a delay before this callback...
            self.spinner.stopAnimating() // activity stopped
            self.setDeleteUserResponse(response: "", forSpeechItemType: speechItemType)
            if let response = response {
                if let userID = response.userID, let condition = response.condition {
                    switch condition {
                    case .good:
                        self.setDeleteUserResponse(response: "Deleted", forSpeechItemType: speechItemType)
                    case .not_enrolled:
                        self.setDeleteUserResponse(response: "Not Enrolled", forSpeechItemType: speechItemType)
                    case .fail, .error:
                        self.setDeleteUserResponse(response: "\(response.extra ?? "fail")", forSpeechItemType: speechItemType)
                    default:
                        logger.log(.error, "Unexpected condition: \(condition) (userID: \(userID), extra: \(response.extra ?? ""))")
                    }
                } else {
                    logger.log(.error, "Invalid response: \(response)")
                }
            } else {
                logger.log(.error, "no response!")
            }
        }
    }
}
