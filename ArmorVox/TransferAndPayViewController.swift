//
//  TransferAndPayViewController.swift
//  ArmorVox
//
//  Created by Rob Dixon on 27/07/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import UIKit

enum TransferOption: String {
    case transfer, payAnyone, payBills, mobile
    
    var image: UIImage {
        return UIImage(named: self.rawValue) ?? UIImage()
    }
    
    var isImplemented: Bool { // used to only enable options which have been implemented
        switch self {
        case .payAnyone:
            return true
        default:
            return false
        }
    }
}



class TransferAndPayViewController: UIViewController {
    
    enum TransferAndPayStage {
        case selectFromAccount, selectOption, selectTo, setAmount, confirmation, authorize, validated
    }
    
    // MARK: - UI
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    let defaultTableViewBottomConstraintConstant = CGFloat(8)
    
    var isShowingKeyboard = false
    
    fileprivate var spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge) // show retrieval activity
    
    
    // MARK: - Constants
    
    let transferOptions: [TransferOption] = [.transfer, .payAnyone, .payBills, .mobile]
    
    
    
    // MARK: - Data
    
    var stage = TransferAndPayStage.selectFromAccount {
        didSet {
            tableView.allowsSelection = true
            switch stage {
            case .selectFromAccount:
                // start the transfer process
                tableData = ["FROM"]
                for account in myAccounts.accounts {
                    tableData.append(account)
                }
                
            case .validated:
                logger.log(.debug, "VALIDATED")
                tableView.allowsSelection = false
                addTableData(rows: ["Payment confirmed"], toTableSection: 0)
                // scroll to bottom
                let row = tableView.numberOfRows(inSection: 0) - 1
                if row > 0 {
                    let iPath = IndexPath(row: row, section: 0)
                    self.tableView.scrollToRow(at: iPath, at: .bottom, animated: true)
                }
                
            default:
                break
            }
            tableView.reloadData()
        }
    }
    
    var tableData: [Any] = []
    
    var myAccounts = MyAccounts.defaultMyAccounts()
    var fromAccount: Account?
    var toAccount = Account.jakesAccount()
    var transferAmount = TransferAmount()
    var transferPayWhen = TransferPayWhen()
    var transfer: Transfer?
    
    // audio recording...
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        stage = .selectFromAccount
        transferAmount = TransferAmount() // reset to 0/blank
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillShow, object: nil, queue: OperationQueue.main) { (notification: Notification) in
            // Keyboard will show...
            // Animate the tableView up, and scroll the bottom row into view
            self.isShowingKeyboard = true
            if let userInfo = notification.userInfo,
                let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue,
                let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as? Double {
                let keyboardHeight = keyboardFrame.cgRectValue.height
                UIView.animate(withDuration: duration, animations: {
                    let tabBarHeight = self.tabBarController?.tabBar.frame.size.height ?? CGFloat(0)
                    self.tableViewBottomConstraint.constant = self.defaultTableViewBottomConstraintConstant + keyboardHeight - tabBarHeight
                    self.view.layoutIfNeeded()
                }, completion: { (finished: Bool) in
                    let row = self.tableView.numberOfRows(inSection: 0) - 1
                    if row >= 0 {
                        let indexPath = IndexPath(row: row, section: 0)
                        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                    }
                })
            }
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillHide, object: nil, queue: OperationQueue.main) { (notification: Notification) in
            self.isShowingKeyboard = false
            // Keyboard will hide...
            // Animate the tableView back down, and scroll the top row into view
            if let userInfo = notification.userInfo,
                let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double {
                UIView.animate(withDuration: duration, animations: {
                    self.tableViewBottomConstraint.constant = self.defaultTableViewBottomConstraintConstant
                    self.view.layoutIfNeeded()
                }, completion: { (finished: Bool) in
                    // after hiding keyboard, scroll tableView to top
                    if self.tableView.numberOfRows(inSection: 0) > 0 {
                        let indexPath = IndexPath(row: 0, section: 0)
                        self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                    }
                })
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // do some clean up, now we've been removed from the screen
        // ...but nothing time-consuming (unless we start a thread)
        // e.g. save scroll position, or save data
        NotificationCenter.default.removeObserver(self)
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
    
    @IBAction func backgroundTapGesture(_ sender: UITapGestureRecognizer) {
        if stage == .setAmount {
            if isShowingKeyboard {
                // detect tap on "Next" while keyboard is showing
                let touchPoint = sender.location(in: tableView)
                if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                    if indexPath.row == 5 { // tap on "Next"
                        
                        // dismiss keyboard
                        self.view.endEditing(true)
                        
                        // Action "Next"
                        tableView(tableView, didSelectRowAt: indexPath)
                        return
                    }
                }
                // dismiss keyboard
                self.view.endEditing(true)
            }
        }
    }

    
    
    // MARK: - Methods
    
    func aurayaVerify(type: SpeechItemType, utterance: Utterance, onSuccessProceedToStage: TransferAndPayStage) {
        guard let userID = UserSettings.shared.userID else {
            logger.log(.error, "Invalid userID!")
            return
        }
        spinner.startAnimating() // activity started
        ArmorVoxAPI.aurayaVerify(sessionID: ArmorVox.sessionID, userID: userID, type: type, utterance: utterance) { (response: ArmorVoxAPIResponse?) in
            // Note: there may be a delay before this callback...
            self.spinner.stopAnimating() // activity stopped
            if let response = response {
                logger.log(.debug, "response: \(response)")
                if let userID = response.userID, let condition = response.condition {
                    switch condition {
                    case .good:
                        self.stage = onSuccessProceedToStage
                        break
                    case .not_enrolled:
                        logger.log(.debug, "Not Enrolled")
                        break
                    case .qafailed:
                        logger.log(.debug, "QA Failed \(response.extra ?? "")")
                        break
                    case .fail, .error:
                        logger.log(.debug, "\(response.extra ?? "fail")")
                        break
                    default:
                        logger.log(.error, "Unexpected condition: \(condition) (userID: \(userID), extra: \(response.extra ?? ""))")
                    }
                }
                
            } else {
                logger.log(.error, "no response!")
            }
        }
    }
    
    func textPromptedVerify(utterance: Utterance, phrase: String, onSuccessProceedToStage: TransferAndPayStage) {
        guard let userID = UserSettings.shared.userID else {
            logger.log(.error, "Invalid userID!")
            return
        }
        spinner.startAnimating() // activity started
        ArmorVoxAPI.textPromptedVerify(sessionID: ArmorVox.sessionID, userID: userID, utterance: utterance, phrase: phrase) { (response: ArmorVoxAPIResponse?) in
            // Note: there may be a delay before this callback...
            self.spinner.stopAnimating() // activity stopped
            if let response = response {
                logger.log(.debug, "response: \(response)")
                if let userID = response.userID, let condition = response.condition {
                    switch condition {
                    case .good:
                        self.stage = onSuccessProceedToStage
                        break
                    case.unsure:
                        logger.log(.debug, "Unsure")
                        break
                    case .not_enrolled:
                        logger.log(.debug, "Not Enrolled")
                        break
                    case .qafailed:
                        logger.log(.debug, "QA Failed \(response.extra ?? "")")
                        break
                    case .fail, .error:
                        logger.log(.debug, "\(response.extra ?? "fail")")
                        break
                    default:
                        logger.log(.error, "Unexpected condition: \(condition) (userID: \(userID), extra: \(response.extra ?? ""))")
                    }
                }
                
            } else {
                logger.log(.error, "no response!")
            }
        }
    }
}


extension TransferAndPayViewController: UITableViewDataSource, UITableViewDelegate {
    
    func configureTableView() {
        tableView.register(UINib(nibName: "AccountTableViewCell", bundle: nil), forCellReuseIdentifier: "AccountTableViewCell")
        tableView.register(UINib(nibName: "TransferOptionsTableViewCell", bundle: nil), forCellReuseIdentifier: "TransferOptionsTableViewCell")
        tableView.register(UINib(nibName: "NewTransferOptionsTableViewCell", bundle: nil), forCellReuseIdentifier: "NewTransferOptionsTableViewCell")
        tableView.register(UINib(nibName: "TransferToTableViewCell", bundle: nil), forCellReuseIdentifier: "TransferToTableViewCell")
        tableView.register(UINib(nibName: "TransferDetailsTableViewCell", bundle: nil), forCellReuseIdentifier: "TransferDetailsTableViewCell")
        tableView.register(UINib(nibName: "TransferPayWhenTableViewCell", bundle: nil), forCellReuseIdentifier: "TransferPayWhenTableViewCell")
        tableView.register(UINib(nibName: "ActionTableViewCell", bundle: nil), forCellReuseIdentifier: "ActionTableViewCell")
        tableView.register(UINib(nibName: "ConfirmationTableViewCell", bundle: nil), forCellReuseIdentifier: "ConfirmationTableViewCell")
        tableView.register(UINib(nibName: "ParagraphTableViewCell", bundle: nil), forCellReuseIdentifier: "ParagraphTableViewCell")
        tableView.register(UINib(nibName: "SpeakTextTableViewCell", bundle: nil), forCellReuseIdentifier: "SpeakTextTableViewCell")
        tableView.rowHeight = UITableViewAutomaticDimension // will use constraints to get row height
        tableView.estimatedRowHeight = 44.0
        tableView.tableFooterView = UIView(frame: .zero) // prevents extra empty rows, below data 
    }
    
    func addTableData(rows: [Any], toTableSection section: Int) {
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
        let obj = tableData[indexPath.row]
        
        if let title = obj as? String { // TITLE
            if title == "Next" || title == "Pay now" || title == "Payment confirmed" { // ACTION
                let cell = tableView.dequeueReusableCell(withIdentifier: "ActionTableViewCell", for: indexPath)
                guard let actionCell = cell as? ActionTableViewCell else {
                    logger.log(.debug, "Error: couldn't get ActionTableViewCell")
                    return cell
                }
                actionCell.title = title
                return actionCell
            }
            // PLAIN TEXT
            let cell = tableView.dequeueReusableCell(withIdentifier: "TitleTableViewCell", for: indexPath)
            cell.textLabel?.text = title
            return cell
            
        } else if let account = obj as? Account { // ACCOUNT
            if stage == .selectTo || stage == .setAmount || stage == .confirmation { // it's an account to pay to
                let cell = tableView.dequeueReusableCell(withIdentifier: "TransferToTableViewCell", for: indexPath)
                guard let toAccountCell = cell as? TransferToTableViewCell else {
                    logger.log(.debug, "Error: couldn't get TransferToTableViewCell")
                    return cell
                }
                toAccountCell.account = account
                return toAccountCell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AccountTableViewCell", for: indexPath)
                guard let fromAccountCell = cell as? AccountTableViewCell else {
                    logger.log(.debug, "Error: couldn't get AccountTableViewCell")
                    return cell
                }
                fromAccountCell.account = account
                return fromAccountCell
            }
            
        } else if let options = obj as? [TransferOption] { // TRANSFEROPTIONS
            let cell = tableView.dequeueReusableCell(withIdentifier: "NewTransferOptionsTableViewCell", for: indexPath)
            guard let optionsCell = cell as? NewTransferOptionsTableViewCell else {
                logger.log(.debug, "Error: couldn't get NewTransferOptionsTableViewCell")
                return cell
            }
            return optionsCell
            
        } else if let transferAmount = obj as? TransferAmount {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TransferDetailsTableViewCell", for: indexPath)
            guard let transferCell = cell as? TransferDetailsTableViewCell else {
                logger.log(.debug, "Error: couldn't get TransferDetailsTableViewCell")
                return cell
            }
            transferCell.transferAmount = transferAmount
            return transferCell
            
        } else if let _ = obj as? TransferPayWhen {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TransferPayWhenTableViewCell", for: indexPath)
            guard let payWhenCell = cell as? TransferPayWhenTableViewCell else {
                logger.log(.debug, "Error: couldn't get TransferPayWhenTableViewCell")
                return cell
            }
            payWhenCell.transferPayWhen = transferPayWhen
            return payWhenCell
        
        } else if let _ = obj as? Transfer {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ConfirmationTableViewCell", for: indexPath)
            guard let confirmationCell = cell as? ConfirmationTableViewCell else {
                logger.log(.debug, "Error: couldn't get ConfirmationTableViewCell")
                return cell
            }
            confirmationCell.transfer = self.transfer
            return confirmationCell
            
        } else if let _ = obj as? TransferTerms {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParagraphTableViewCell", for: indexPath)
            guard let paragraphCell = cell as? ParagraphTableViewCell else {
                logger.log(.debug, "Error: couldn't get ParagraphTableViewCell")
                return cell
            }
            paragraphCell.paragraph = TransferTerms().terms
            return paragraphCell
            
        } else if let _ = obj as? AuthorizeInstructions {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParagraphTableViewCell", for: indexPath)
            guard let paragraphCell = cell as? ParagraphTableViewCell else {
                logger.log(.debug, "Error: couldn't get ParagraphTableViewCell")
                return cell
            }
            paragraphCell.paragraph = AuthorizeInstructions().text
            return paragraphCell
        
        } else if let speakText = obj as? SpeakText {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SpeakTextTableViewCell", for: indexPath)
            guard let speakTextCell = cell as? SpeakTextTableViewCell else {
                logger.log(.debug, "Error: couldn't get SpeakTextTableViewCell")
                return cell
            }
            speakTextCell.textToSpeak = speakText.text
            return speakTextCell
            
        } else if let speakItem = obj as? SpeakItem {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SpeakTextTableViewCell", for: indexPath)
            guard let speakTextCell = cell as? SpeakTextTableViewCell else {
                logger.log(.debug, "Error: couldn't get SpeakTextTableViewCell")
                return cell
            }
            speakTextCell.textToSpeak = speakItem.string
            speakTextCell.done = speakItem.recordedSuccessfully
            if indexPath.isSectionLastRow(inTableView: tableView) && recordingMode == .recording {
                speakTextCell.backgroundColor = UIColor.backgroundWhenRecording
            } else {
                speakTextCell.backgroundColor = UIColor.backgroundWhenNotRecording
            }
            return speakTextCell
            
        } else { // unhandled tableData obj
            logger.log(.error, "Unhandled tableData object: \(obj)")
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TitleTableViewCell", for: indexPath)
        return cell
    }
    
    
    
    // MARK: - tableView, SELECTION
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { // Delegate
        
        let obj = tableData[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)

        switch stage {

        case .selectFromAccount: // user selected a FROM account
            if let account = obj as? Account {
                fromAccount = account
                // Animate the removal of all FROM accounts, except the selected one
                tableView.beginUpdates()
                var rows: [Int] = []
                for row in (1..<tableData.count).reversed() {
                    if let _ = tableData[row] as? Account {
                        if row != indexPath.row {
                            rows.append(row)
                            tableData.remove(at: row)
                        }
                    }
                }
                tableView.deleteRows(rows: rows, fromSection: indexPath.section, with: .top)
                tableView.endUpdates()
                // Add rows to select "TO" account
                let dispatchTime = DispatchTime.now() + .milliseconds(500)
                DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                    self.addTableData(rows: ["TO", self.transferOptions], toTableSection: indexPath.section)
                    self.stage = .selectOption
                })
            }
            
        case .selectOption: // user selected the transfer option...
            if let _ = obj as? [TransferOption] {
                // remove "FROM" and the from account
                tableView.beginUpdates()
                tableData.removeFirst()
                tableData.removeFirst()
                tableView.deleteRows(rows: [0, 1], fromSection: indexPath.section, with: .top)
                tableView.endUpdates()
                // Add the "TO" account
                let dispatchTime = DispatchTime.now() + .milliseconds(500)
                DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                    self.addTableData(rows: [self.toAccount], toTableSection: indexPath.section)
                    self.stage = .selectTo
                })
            }
            
        case .selectTo: // user selected the account to transfer TO
            if let _ = obj as? Account {
                // Add the transfer details
                let dispatchTime = DispatchTime.now() + .milliseconds(500)
                DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                    self.addTableData(rows: [self.transferAmount, self.transferPayWhen, "Next"], toTableSection: indexPath.section)
                    self.stage = .setAmount
                })
            }
            
        case .setAmount:
            if let title = obj as? String,
                title == "Next" {
                guard transferAmount.isValid else {
                    logger.log(.error, "Invalid transfer")
                    return
                }
                guard let from = fromAccount else {
                    logger.log(.error, "No From Account!")
                    return
                }
                // confirmation...
                self.transfer = Transfer(transferAmount: transferAmount, fromAccount: from, toAccount: toAccount, payWhen: transferPayWhen.payWhen)
                
                // clear the table...
                tableView.beginUpdates()
                tableData = []
                tableView.deleteAllRows(inSection: indexPath.section, with: .top)
                tableView.endUpdates()
                // Show confirmation
                let dispatchTime = DispatchTime.now() + .milliseconds(500)
                DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                    self.addTableData(rows: [self.transfer!, TransferTerms(), "Pay now"], toTableSection: indexPath.section)
                    // scroll to bottom
                    let iPath = IndexPath(row: 2, section: indexPath.section)
                    self.tableView.scrollToRow(at: iPath, at: .bottom, animated: true)
                    self.stage = .confirmation
                })
            }
            break
            
        case .confirmation:
            if let title = obj as? String,
                title == "Pay now" {
                // proceed to authorize
                // remove terms and "Pay now"
                tableView.beginUpdates()
                tableData.removeLast()
                tableData.removeLast()
                tableView.deleteRows(rows: [1, 2], fromSection: indexPath.section, with: .top)
                tableView.endUpdates()
                // Add authorize...
                let dispatchTime = DispatchTime.now() + .milliseconds(500)
                DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                    // Add row depending on verificationType
                    switch AppSettings.shared.verificationType {
                    case .phrase:
                        // speak phrase
                        let promptString = UserSettings.shared.phraseEnrolmentVariation.description
                        self.addTableData(rows: [AuthorizeInstructions(), SpeakItem(string: promptString)], toTableSection: indexPath.section)
                        break
                    case .numbers:
                        // speak random number
                        self.addTableData(rows: [AuthorizeInstructions(), SpeakItem(string: Verification.randomNumberString())], toTableSection: indexPath.section)
                        break
                    }
                    self.stage = .authorize
                })
            }

        case .authorize:
            if let speakItem = obj as? SpeakItem {
                if indexPath.isSectionLastRow(inTableView: tableView) {
                    logger.log(.debug, "Start voice recording, speak \"\(speakItem.string)\"")
                    switch recordingMode {
                    case.notReady:
                        logger.log(.error, "Not ready to record")
                        break
                    case .ready:
                        // Record Utterance
                        let filename = "Utterance"
                        if audioRecorder.record(filename: filename, completion: { (url: URL?, newRecordingMode: RecordingMode) in
                            // RECORDING COMPLETION CLOSURE
                            //logger.log(.debug, "RECORDING COMPLETION CLOSURE")
                            self.recordingMode = newRecordingMode // this will normally be .ready
                            if let utteranceURL = url  { // success, got recording at url
                                logger.log(.debug, "file: \(utteranceURL.lastPathComponent)")
                                speakItem.recordedSuccessfully = true
                                tableView.reloadRows(at: [indexPath], with: .fade) // will show tick
                                switch AppSettings.shared.verificationType {
                                case .phrase:
                                    // aurayaVerify .phrase (8) utteranceURL
                                    self.aurayaVerify(type: .phrase, utterance: utteranceURL, onSuccessProceedToStage: .validated)
                                    break
                                case .numbers:
                                    // textPromptedVerify utteranceURL, speakItem.spelling, omit vocab
                                    logger.log(.error, "phrase: \(speakItem.spelling)")
                                    self.textPromptedVerify(utterance: utteranceURL, phrase: speakItem.spelling, onSuccessProceedToStage: .validated)
                                    break
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
                    
                    
                } // lastrow
            } // speakItem
            
        case .validated:
            logger.log(.debug, "SUCCESS")
            
        } // switch stage
    }
}







enum TransferCells {
    // Note:
    // not used yet...
    case plainText(text: String),
    actionText(text: String),
    fromAccount(account: Account),
    toAccount(account: Account),
    options,
    transferAmount(transferAmount: TransferAmount),
    payWhen(payWhen: PayWhen),
    confirmation(transfer: Transfer),
    terms,
    authorize(transfer: Transfer)
}

















