//
//  APITestsViewController.swift
//  ArmorVox
//
//  Created by Rob Dixon on 04/08/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import UIKit

class APITestsViewController: UIViewController {
    
    // MARK: - UI
    @IBOutlet weak var checkEnrolledButton: UIButton!
    @IBOutlet weak var isEnrolledLabel: UILabel! {
        didSet {
            isEnrolledLabel.text = ""
        }
    }
    @IBOutlet weak var deleteUserButton: UIButton!
    @IBOutlet weak var deleteUserLabel: UILabel! {
        didSet {
            deleteUserLabel.text = ""
        }
    }
    @IBOutlet weak var aboutLabel: UILabel!
    
    
    
    fileprivate var spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge) // show retrieval activity
    
    
    
    // MARK: - Data
    
    fileprivate var enrolledByPhraseString = "" {
        didSet {
            isEnrolledLabel.text = "\(enrolledByPhraseString) \n\(enrolledByTextPromptedString)"
        }
    }
    fileprivate var enrolledByTextPromptedString = "" {
        didSet {
            isEnrolledLabel.text = "\(enrolledByPhraseString) \n\(enrolledByTextPromptedString)"
        }
    }
    
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
        let aboutString = "Utility API calls, which it might be useful to call directly, during testing. \nOn tapping a button, the response is shown. \nWhen running the app from Xcode, further (diagnostic) information is logged to the console."
        aboutLabel.text = aboutString
    }
    
    override func viewDidLayoutSubviews() {
        // autolayout has happened...
        super.viewDidLayoutSubviews()
        spinner.positionAtCenter(view) // position spinner at center of (some) view
    }
    
    
    
    // MARK: - Action
    
    @IBAction func checkEnrolledButtonPress(_ sender: UIButton) {
        clearUI()
        checkEnrolled(speechItemType: .phrase) // .phrase or .textPrompted
        checkEnrolled(speechItemType: .textPrompted) // .phrase or .textPrompted
    }
    
    @IBAction func deleteUserButtonPress(_ sender: UIButton) {
        clearUI()
        deleteUser(speechItemType: .phrase) // .phrase or .textPrompted
        deleteUser(speechItemType: .textPrompted) // .phrase or .textPrompted
        UserSettings.shared.phraseEnrolmentStatus = .readyToEnrol
        UserSettings.shared.numbersEnrolmentStatus = .readyToEnrol
    }
    
    func clearUI() {
        isEnrolledLabel.text = ""
        deleteUserLabel.text = ""
    }
    
    func setCheckEnrolledResponse(response: String, forSpeechItemType speechItemType: SpeechItemType) {
        switch speechItemType {
        case .phrase:
            enrolledByPhraseString = "\(speechItemType): \(response)"
        case .textPrompted:
            enrolledByTextPromptedString = "\(speechItemType): \(response)"
        default:
            break
        }
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
    
    func checkEnrolled(speechItemType: SpeechItemType) {
        guard let userID = UserSettings.shared.userID else {
            logger.log(.error, "Invalid userID!")
            return
        }
        spinner.startAnimating() // activity started
        setCheckEnrolledResponse(response: "Checking...", forSpeechItemType: speechItemType)
        ArmorVoxAPI.checkEnrolled(sessionID: ArmorVox.sessionID, userID: userID, type: speechItemType) { (response: ArmorVoxAPIResponse?) in
            // Note: there may be a delay before this callback...
            self.spinner.stopAnimating() // activity stopped
            self.setCheckEnrolledResponse(response: "", forSpeechItemType: speechItemType)
            if let response = response {
                //logger.log(.debug, "response: \(response)")
                if let userID = response.userID, let condition = response.condition {
                    switch condition {
                    case .enrolled:
                        self.setCheckEnrolledResponse(response: "Enrolled", forSpeechItemType: speechItemType)
                        UserSettings.shared.setStatus(.enrolled, forVerificationType: VerificationType.forSpeechItemType(speechItemType))
                    case .not_enrolled:
                        self.setCheckEnrolledResponse(response: "Not Enrolled", forSpeechItemType: speechItemType)
                        UserSettings.shared.setStatus(UserSettings.shared.isReadyToEnrol, forVerificationType: VerificationType.forSpeechItemType(speechItemType))
                    case .fail, .error:
                        self.setCheckEnrolledResponse(response: "\(response.extra ?? "fail")", forSpeechItemType: speechItemType)
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
    
    /*
    func aurayaVerify(utterance: Utterance) {
        guard let userID = UserSettings.shared.userID else {
            logger.log(.error, "Invalid userID!")
            return
        }
        spinner.startAnimating() // activity started
        verifyLabel.text = "Verifying..."
        ArmorVoxAPI.aurayaVerify(sessionID: ArmorVox.sessionID, userID: userID, type: .id, utterance: utterance) { (response: ArmorVoxAPIResponse?) in
            // Note: there may be a delay before this callback...
            self.spinner.stopAnimating() // activity stopped
            self.verifyLabel.text = ""
            if let response = response {
                logger.log(.debug, "response: \(response)")
                if let userID = response.userID, let condition = response.condition {
                    switch condition {
                    case .good:
                        self.verifyLabel.text = "Good\n\(response.extra ?? "")"
                    case .not_enrolled:
                        self.verifyLabel.text = "Not Enrolled"
                    case .qafailed:
                        self.verifyLabel.text = "QA Failed \(response.extra ?? "")"
                    case .fail, .error:
                        self.verifyLabel.text = "\(response.extra ?? "fail")"
                    default:
                        logger.log(.error, "Unexpected condition: \(condition) (userID: \(userID), extra: \(response.extra ?? ""))")
                    }
                }
                
            } else {
                logger.log(.error, "no response!")
            }
        }
    }
    */
}
