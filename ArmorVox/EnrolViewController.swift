//
//  EnrolViewController.swift
//  ArmorVox
//
//  Created by Rob Dixon on 03/08/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import UIKit

class EnrolViewController: UIViewController {
    
    enum EnrolStage {
        case notReadyToEnrol, alreadyEnrolled, welcome, consent, choosePhrase, speakPhrase, speakNumbers, enrolled
    }
    
    enum EnrolCellType { // the different types of tableViewCell that we use
        case
        enrolYourVoice,
        paragraph(text: String),
        warning(text: String),
        actionText(text: String),
        speakText(item: SpeakItem)
        
        var cellID: String {
            switch self {
            case .enrolYourVoice:
                return "EnrolYourVoiceTableViewCell"
            case .paragraph( _):
                return "ParagraphTableViewCell"
            case .warning( _):
                return "WarningTableViewCell"
            case .actionText( _):
                return "ActionTableViewCell"
            case .speakText( _):
                return "SpeakTextTableViewCell"
            }
        }
    }
    

    
    // MARK: - UI
    
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge) // show retrieval activity

    
    
    // MARK: - Constants
    struct Strings {
        static let notReadyToEnrolString = "Before enrolling, please enter your phone number."
        static let alreadyEnrolledString = "You are already enrolled!"
        static let consentGivenString = "I consent to using voice biometrics."
        static let consentLaterString = "I will enrol my voice later."
        static let quietEnvironmentString = "Please ensure that you are in a quiet environment before you continue."
        static let welcomeMessageString = "By enrolling your voice print, you can secure all future transactions with your voice. We will use your voice as biometric identification and authentication for all future transactions to protect your personal assets and information."
        static let promptToSpeakString = "Please touch the microphone and say"
        static let successString = "YOUR VOICE HAS BEEN SUCCESSFULLY ENROLLED.\n\nTHANK YOU FOR BANKING WITH ACME."
    }
    
    
    
    // MARK: - Data
    
    var stage = EnrolStage.welcome {
        didSet {
            switch stage {
            
            case .notReadyToEnrol:
                tableView.allowsSelection = false
                tableData = [.warning(text: Strings.notReadyToEnrolString)]
                
            case .alreadyEnrolled:
                tableView.allowsSelection = false
                tableData = [.warning(text: Strings.alreadyEnrolledString)]
                
            case .welcome:
                // start the transfer process
                tableView.allowsSelection = false
                tableData = [
                    .enrolYourVoice,
                    .paragraph(text: Strings.welcomeMessageString)
                ]
                // After a short delay, proceed to .consent stage
                let dispatchTime = DispatchTime.now() + .milliseconds(1000)
                DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                    self.addTableData(rows: [
                        EnrolCellType.warning(text: Strings.quietEnvironmentString),
                        EnrolCellType.actionText(text: Strings.consentGivenString),
                        EnrolCellType.actionText(text: Strings.consentLaterString)
                        ], toTableSection: 0)
                    self.stage = .consent
                })
                
            case .speakPhrase:
                if let speakPhrase = enrolVoice.nextPhrase {
                    addTableData(rows: [EnrolCellType.speakText(item: speakPhrase)], toTableSection: 0)
                }
                
            case .speakNumbers:
                if let speakNumber = enrolVoice.nextNumber {
                    addTableData(rows: [EnrolCellType.speakText(item: speakNumber)], toTableSection: 0)
                }
                
            case .enrolled:
                tableView.allowsSelection = false
                logger.log(.debug, "ENROLLED *****")
                UserSettings.shared.overallStatus = .enrolled
                // proceed...
                // clear the table...
                tableView.beginUpdates()
                tableData = []
                tableView.deleteAllRows(inSection: 0, with: .top)
                tableView.endUpdates()
                // Show confirmation
                let dispatchTime = DispatchTime.now() + .milliseconds(500)
                DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                    self.addTableData(rows: [EnrolCellType.paragraph(text: Strings.successString)], toTableSection: 0)
                })
                
            default:
                tableView.allowsSelection = true
                break
            }
            tableView.reloadData()
        }
    }

    var tableData: [EnrolCellType] = []
    
    var enrolVoice = EnrolVoice(phrase: SpeakItem(string: ""))
    
    let audioRecorder = AudioRecorder()
    var recordingMode = RecordingMode.notReady {
        didSet {
            switch recordingMode {
            case .notReady:
                view.backgroundColor = UIColor.backgroundWhenNotRecording
            case .ready:
                view.backgroundColor = UIColor.backgroundWhenNotRecording
            case .recording:
                view.backgroundColor = UIColor.backgroundWhenRecording
            }
        }
    }
    
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // add the activity spinner
        spinner.addTo(view)
        configureTableView()
        
        // audioRecorder
        audioRecorder.delegate = audioRecorder
        if audioRecorder.prepareToRecord() {
            recordingMode = .ready
        }
        // subscribe to notification that we're ready to record
        NotificationCenter.default.addObserver(forName: AudioRecorder.Notifications.readyToRecord, object: nil, queue: OperationQueue.main) { (notification) in
            if self.recordingMode == .notReady {
                self.recordingMode = .ready
            }
        }
        
        // setup enrolVoice
        if UserSettings.shared.overallStatus == .readyToEnrol {
            let promptString = UserSettings.shared.phraseEnrolmentVariation.description
            enrolVoice = EnrolVoice(phrase: SpeakItem(string: promptString))
        }

        // NOTE:
        // Title is too big to fit on iPhone SE width...
        self.title = "Welcome to ACME Voice Biometrics"
        let frame = CGRect(x: 0, y: 0, width: 200, height: 40)
        let tlabel = UILabel(frame: frame)
        tlabel.text = self.title
        tlabel.font = UIFont.boldSystemFont(ofSize: 17)
        tlabel.adjustsFontSizeToFitWidth = true
        self.navigationItem.titleView = tlabel
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        switch UserSettings.shared.overallStatus {
        case .notReadyToEnrol:
            stage = .notReadyToEnrol
        case .readyToEnrol:
            stage = .welcome
        case .enrolled:
            stage = .alreadyEnrolled
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if audioRecorder.isRecording {
            audioRecorder.stop()
            recordingMode = .ready
        }
        audioRecorder.deleteRecordings()
    }
    
    override func viewDidLayoutSubviews() {
        // autolayout has happened...
        super.viewDidLayoutSubviews()
        spinner.positionAtCenter(view) // position spinner at center of (some) view
    }
    
    
    
    // MARK: - Action
    
    
    
    // MARK: - Methods
    
    func aurayaEnrolPhrase(utterances: [Utterance], onSuccessProceedToStage: EnrolStage) {
        // aurayaEnrol .phrase (8)
        // On success, proceed to the given stage
        guard let userID = UserSettings.shared.userID  else {
            logger.log(.error, "No userID")
            return
        }
        self.spinner.startAnimating() // activity started
        ArmorVoxAPI.auraya_enrol(sessionID: ArmorVox.sessionID, userID: userID, type: .phrase, utterances: utterances) { (response: ArmorVoxAPIResponse?) in
            // Note: there may be a delay before this callback...
            self.spinner.stopAnimating() // activity stopped
            if let response = response {
                if let userID = response.userID, let condition = response.condition {
                    switch condition {
                    case .enrolled: // mistake, but can proceed
                        logger.log(.warning, "Already enrolled")
                        self.stage = onSuccessProceedToStage
                    case .good: // SUCCESS, proceed
                        logger.log(.debug, "aurayaEnrol: SUCCESS")
                        self.stage = onSuccessProceedToStage
                    case .repeatall:
                        logger.log(.error, "Repeat all")
                    case .fail, .error:
                        logger.log(.error, "\(response.extra ?? "fail")")
                    default:
                        logger.log(.error, "Unexpected condition: \(condition) (userID: \(userID), extra: \(response.extra ?? ""))")
                    }
                } else {
                    logger.log(.error, "Invalid response: \(response)")
                }
            } else {
                logger.log(.error, "no response!")
            }
        } // auraya_enrol
    }
    
    func aurayaEnrolNumbers(utterances: [Utterance], phrases: [String], onSuccessProceedToStage: EnrolStage) {
        // text_prompted_enrol
        // On success, proceed to the given stage
        guard let userID = UserSettings.shared.userID  else {
            logger.log(.error, "No userID")
            return
        }
        self.spinner.startAnimating() // activity started
        ArmorVoxAPI.text_prompted_enrol(sessionID: ArmorVox.sessionID, userID: userID, utterances: utterances, phrases: phrases) { (response: ArmorVoxAPIResponse?) in
            // Note: there may be a delay before this callback...
            self.spinner.stopAnimating() // activity stopped
            if let response = response {
                if let userID = response.userID, let condition = response.condition {
                    switch condition {
                    case .enrolled: // mistake, but can proceed
                        logger.log(.warning, "Already enrolled")
                        self.stage = onSuccessProceedToStage
                    case .good: // SUCCESS, proceed
                        logger.log(.debug, "text_prompted_enrol: SUCCESS")
                        self.stage = onSuccessProceedToStage
                    case .repeatall:
                        logger.log(.error, "Repeat all")
                    case .fail, .error:
                        logger.log(.error, "\(response.extra ?? "fail")")
                    default:
                        logger.log(.error, "Unexpected condition: \(condition) (userID: \(userID), extra: \(response.extra ?? ""))")
                    }
                } else {
                    logger.log(.error, "Invalid response: \(response)")
                }
            } else {
                logger.log(.error, "no response!")
            }
        } // auraya_enrol
    }
    
    
    
    // MARK: - Navigation

    

}



// MARK: - tableView
extension EnrolViewController: UITableViewDataSource, UITableViewDelegate {
    
    func configureTableView() {
        // register tableViewCells...
        for enrolCellType: EnrolCellType in [.enrolYourVoice, .paragraph(text: ""), .warning(text: ""), .actionText(text: ""), .speakText(item: SpeakItem(string: ""))] {
            tableView.register(UINib(nibName: enrolCellType.cellID, bundle: nil), forCellReuseIdentifier: enrolCellType.cellID)
        }
        tableView.rowHeight = UITableViewAutomaticDimension // will use constraints to get row height
        tableView.estimatedRowHeight = 44.0
    }
    
    func addTableData(rows: [EnrolCellType], toTableSection section: Int) {
        tableView.beginUpdates()
        tableData.append(contentsOf: rows)
        tableView.appendRows(numRows: rows.count, inSection: section, with: .bottom)
        tableView.endUpdates()
    }
    
    
    
    
    // MARK: - tableView, REQUIRED
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { // DataSource
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { // DataSource
        let enrolCellType = tableData[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: enrolCellType.cellID, for: indexPath)
        switch enrolCellType {
         
        case .enrolYourVoice:
            guard let enrolYourVoiceCell = cell as? EnrolYourVoiceTableViewCell else {
                logger.log(.debug, "Error: couldn't get EnrolYourVoiceTableViewCell")
                return cell
            }
            return enrolYourVoiceCell
            
        case .paragraph(let text):
            guard let paragraphCell = cell as? ParagraphTableViewCell else {
                logger.log(.debug, "Error: couldn't get ParagraphTableViewCell")
                return cell
            }
            paragraphCell.paragraph = text
            return paragraphCell
            
        case .warning(let message):
            guard let warningCell = cell as? WarningTableViewCell else {
                logger.log(.debug, "Error: couldn't get WarningTableViewCell")
                return cell
            }
            warningCell.message = message
            return warningCell
            
        case .actionText(let text):
            guard let actionCell = cell as? ActionTableViewCell else {
                logger.log(.debug, "Error: couldn't get ActionTableViewCell")
                return cell
            }
            actionCell.title = text
            return actionCell
            
        case .speakText(let item):
            guard let speakTextCell = cell as? SpeakTextTableViewCell else {
                logger.log(.debug, "Error: couldn't get SpeakTextTableViewCell")
                return cell
            }
            speakTextCell.textToSpeak = item.string
            speakTextCell.done = item.recordedSuccessfully
            if indexPath.isSectionLastRow(inTableView: tableView) && recordingMode == .recording {
                speakTextCell.backgroundColor = UIColor.backgroundWhenRecording
            } else {
                speakTextCell.backgroundColor = UIColor.backgroundWhenNotRecording
            }
            return speakTextCell
        }
    }
    
    // MARK: - tableView, SECTIONS
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { // Delegate
        return 1.0 // note: 0 doesn't work, use 1.0 to "hide" header
    }
    
    
    
    // MARK: - tableView, SELECTION
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { // Delegate
        
        let cellType = tableData[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch stage {
            
        case .consent: // user selected a FROM account
            switch cellType {
            case .actionText(let actionText):
                if actionText == Strings.consentLaterString { // consent not given - dismiss
                    performSegue(withIdentifier: "UnwindToMore", sender: self)
                }
                if actionText == Strings.consentGivenString { // consent given - proceed
                    guard tableData.count == 5 else {
                        logger.log(.error, "Expected 5 table rows, found: \(tableData.count)")
                        return
                    }
                    // remove consent cells
                    tableView.beginUpdates()
                    tableData.removeLast()
                    tableData.removeLast()
                    tableData.removeLast()
                    tableView.deleteRows(rows: [2, 3, 4], fromSection: indexPath.section, with: .top)
                    tableView.endUpdates()
                    // speakNumbers
                    let dispatchTime = DispatchTime.now() + .milliseconds(500)
                    DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                        self.addTableData(rows: [EnrolCellType.paragraph(text: Strings.promptToSpeakString)
                                                 ], toTableSection: indexPath.section)
                        self.stage = .speakPhrase
                    })
                }
            default:
                logger.log(.error, "Unhandled cellType: \(cellType)")
                break
            }
            break
          
        case .speakPhrase:
            if indexPath.isSectionLastRow(inTableView: tableView) { // last row
                let enrolCellType = tableData[indexPath.row]
                switch enrolCellType {
                case .speakText(let phrase):
                    // aurayaEnroll Phrase, Type 8, Utterance1..3
                    logger.log(.debug, "Start voice recording, speak \"\(phrase.string)\"")
                    switch recordingMode {
                    case.notReady:
                        logger.log(.error, "Not ready to record")
                        break
                    case .ready:
                        
                        // Record Phrase Utterances
                        let filename = "Utterance" + "\(enrolVoice.phraseUtterances.count + 1)"
                        if audioRecorder.record(filename: filename, completion: { (url: URL?, newRecordingMode: RecordingMode) in
                            // RECORDING COMPLETION CLOSURE
                            //logger.log(.debug, "RECORDING COMPLETION CLOSURE")
                            self.recordingMode = newRecordingMode // this will normally be .ready
                            if let utteranceURL = url  { // success, got recording at url
                                logger.log(.debug, "file: \(utteranceURL.lastPathComponent)")
                                self.enrolVoice.phraseUtterances.append(utteranceURL)
                                self.enrolVoice.doneCurrentPhrase(success: true)
                                tableView.reloadRows(at: [indexPath], with: .fade) // will show tick
                                if let speakPhrase = self.enrolVoice.nextPhrase { // must speak again
                                    self.addTableData(rows: [EnrolCellType.speakText(item: speakPhrase)], toTableSection: indexPath.section)
                                    
                                } else { // phrase done 3x - enrol
                                    // aurayaEnrol .phrase (8)
                                    self.aurayaEnrolPhrase(utterances: self.enrolVoice.phraseUtterances, onSuccessProceedToStage: .speakNumbers)
                                    
                                }
                            } else { // voice recording failure
                                logger.log(.error, "Voice Recording failed")
                            }
                        }) {
                            //Recording started successfully
                            recordingMode = .recording
                            tableView.reloadRows(at: [indexPath], with: .fade) // will show recording
                        }

                    case .recording:
                        audioRecorder.stop() // leave this in??
                    } // switch recordingMode
                    
                default:
                    logger.log(.error, "Expected speakText")
                    break
                }
            }
            break
            
        case .speakNumbers:
            if indexPath.isSectionLastRow(inTableView: tableView) { // last row
                let enrolCellType = tableData[indexPath.row]
                switch enrolCellType {
                case .speakText(let number):
                    // text_prompted_enrol Utterance1..5, Phrase1..5
                    logger.log(.debug, "Start voice recording, speak \"\(number.string)\"")
                    switch recordingMode {
                    case.notReady:
                        logger.log(.error, "Not ready to record")
                        break
                    case .ready:
                        
                        // Record Phrase Utterances
                        let filename = "Utterance" + "\(enrolVoice.numberUtterances.count + 1)"
                        if audioRecorder.record(filename: filename, completion: { (url: URL?, newRecordingMode: RecordingMode) in
                            // RECORDING COMPLETION CLOSURE
                            //logger.log(.debug, "RECORDING COMPLETION CLOSURE")
                            self.recordingMode = newRecordingMode // this will normally be .ready
                            if let utteranceURL = url  { // success, got recording at url
                                logger.log(.debug, "file: \(utteranceURL.lastPathComponent)")
                                self.enrolVoice.numberUtterances.append(utteranceURL)
                                self.enrolVoice.doneCurrentNumber(success: true)
                                tableView.reloadRows(at: [indexPath], with: .fade) // will show tick
                                if let speakNumber = self.enrolVoice.nextNumber { // another number
                                    self.addTableData(rows: [EnrolCellType.speakText(item: speakNumber)], toTableSection: indexPath.section)
                                    // scroll to bottom
                                    let iPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
                                    self.tableView.scrollToRow(at: iPath, at: .bottom, animated: true)
                                    
                                } else { // numbers done - enrol
                                    // text_prompted_enrol
                                    let numberPhrases: [String] = self.enrolVoice.numberPhrases ?? []
                                    self.aurayaEnrolNumbers(utterances: self.enrolVoice.numberUtterances, phrases: numberPhrases, onSuccessProceedToStage: .enrolled)
                                    
                                }
                            } else { // voice recording failure
                                logger.log(.error, "Voice Recording failed")
                            }
                        }) {
                            //Recording started successfully
                            recordingMode = .recording
                            tableView.reloadRows(at: [indexPath], with: .fade) // will show recording
                        }
                        
                    case .recording:
                        audioRecorder.stop() // leave this in??
                    } // switch recordingMode
                    
                default:
                    logger.log(.error, "Expected speakText")
                    break
                }
            }
            break
            
        default:
            logger.log(.error, "Unhandled stage: \(stage)")
            break
        }
    }
}






















