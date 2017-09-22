//
//  MyAccountsViewController.swift
//  ArmorVox
//
//  Created by Rob Dixon on 27/07/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import UIKit

class MyAccountsViewController: UIViewController {

    // MARK: - UI
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var greetingNameLabel: UILabel!
    
    weak fileprivate var myAlert: UIAlertController? // used to detect if alert is showing (set with myAlert = alertController)
    
    
    
    // MARK: - Data
    
    var myAccounts = MyAccounts.defaultMyAccounts()
    var didShowPrepareToEnrolAlert = false // used to avoid repeated showings
    var didShowEnrolNowAlert = false // used to avoid repeated showings
    
    
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()        
        let cellNib = UINib(nibName: "AccountTableViewCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "AccountTableViewCell")
        configureTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        greetingLabel.text = greetingString()
        greetingNameLabel.text = UserSettings.shared.name ?? "" // myAccounts.givenName.uppercased()
        
        // register for notification for backgrounding, then we can take appropriate action (remove alert, if showing)
        NotificationCenter.default.addObserver(forName: Notification.Name.UIApplicationDidEnterBackground, object: UIApplication.shared, queue: OperationQueue.main) { notification in
            // take action on backgrounding...
            if let alert = self.myAlert { // alert is showing - get rid of it, so it's not showing when we come back to the foreground (also may want to updateUI, to be sure that everything is up-to-date
                alert.dismiss(animated: false, completion: nil)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Prompt to enrol for biometric voice identification?
        switch UserSettings.shared.overallStatus {
        case .notReadyToEnrol:
            if !didShowPrepareToEnrolAlert { // only show it once - if cancelled, they can choose in manually
                // After a short delay...
                let dispatchTime = DispatchTime.now() + .milliseconds(1000)
                DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                    self.showPrepareToEnrolAlert()
                })
            }
        case .readyToEnrol:
            if !didShowEnrolNowAlert { // only show it once - if cancelled, they can choose in manually
                // After a short delay...
                let dispatchTime = DispatchTime.now() + .milliseconds(1000)
                DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                    self.showEnrolNowAlert()
                })
            }
            break
        case .enrolled:
            break
        }
    }
    
    
    
    // MARK: - Action
    
    
    
    // MARK: - Methods
    
    func greetingString() -> String {
        // return a time-appropriate greeting string (morning, afternoon)
        let hour = Calendar.current.component(.hour, from: Date())
        return hour < 12 ? "Good Morning" : "Good Afternoon"
    }
    
    func showPrepareToEnrolAlert() {
        let alertController = UIAlertController(title: "Acme Bank", message: "Would you like to prepare to enrol for biometric voice identification?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (action: UIAlertAction) -> Void in
            // no action required
        })
        alertController.addAction(UIAlertAction(title: "Prepare to Enrol", style: .default) { (action: UIAlertAction) -> Void in
            self.performSegue(withIdentifier: "EnterUserSettings", sender: self)
        })
        present(alertController, animated: true) {
            self.myAlert = alertController
            self.didShowPrepareToEnrolAlert = true
        }
    }
    
    func showEnrolNowAlert() {
        let alertController = UIAlertController(title: "Acme Bank", message: "Would you like to enrol now?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (action: UIAlertAction) -> Void in
            // no action required
        })
        alertController.addAction(UIAlertAction(title: "Enrol Now", style: .default) { (action: UIAlertAction) -> Void in
            self.performSegue(withIdentifier: "EnrolNow", sender: self)
        })
        present(alertController, animated: true) {
            self.myAlert = alertController
            self.didShowEnrolNowAlert = true
        }
    }

}


extension MyAccountsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func configureTableView() {
        tableView.rowHeight = UITableViewAutomaticDimension // will use constraints to get row height
        tableView.estimatedRowHeight = 44.0
        tableView.tableFooterView = UIView(frame: .zero) // prevents extra empty rows, below data 
    }
    
    // MARK: - tableView, REQUIRED
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { // DataSource
        return myAccounts.accounts.count + 1 // +1 for account summary
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { // DataSource
        
        if indexPath.row < myAccounts.accounts.count { // account
            let cell = tableView.dequeueReusableCell(withIdentifier: "AccountTableViewCell", for: indexPath)
            guard let accountCell = cell as? AccountTableViewCell else {
                logger.log(.debug, "Error: couldn't get AccountTableViewCell")
                return cell
            }
            // retrieve the corresponding data model object
            let account = myAccounts.accounts[indexPath.row]
            // configure the cell
            accountCell.account = account
            return accountCell
            
        } else { // account summary
            let cell = tableView.dequeueReusableCell(withIdentifier: "AccountSummaryTableViewCell", for: indexPath)
            guard let summaryCell = cell as? AccountSummaryTableViewCell else {
                logger.log(.debug, "Error: couldn't get AccountSummaryTableViewCell")
                return cell
            }
            // configure the cell
            summaryCell.myAccounts = myAccounts
            return summaryCell
        }
    }
}

// MARK: - Navigation
extension MyAccountsViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // NOTE: destination outlets are not set, when this is called
        if let identifier = segue.identifier {
            switch identifier {
                
            case "EnrolNow":
                var destination = segue.destination
                if let navCon = segue.destination as? UINavigationController {
                    destination = navCon.visibleViewController! // this lets us cope with the case where our vc is embedded in a navigation controller
                }
                if let destinationVC = destination as? EnrolViewController {
                    // retrieve info from sender (as it's correct class)
                    // ... and use it to set up the destinationVC
                    // NOTE: this is happening BEFORE outlets get set!
                    // EnrolVoiceVC hides the TabBar...
                    destinationVC.hidesBottomBarWhenPushed = true
                    
                } else { // unexpected class of destinationViewController
                    logger.log(.warning, "Unexpected segue destination: \(segue.destination)")
                }
                
            case "EnterUserSettings":
                // no action required, just go to the screen...
                break
                
            default: // unhandled segue identifier
                logger.log(.warning, "Unhandled segue (identifier: \(segue.identifier ?? ""))")
            }
        } else {
            logger.log(.warning, "No segue identifier")
        }
    }
    
    @IBAction func unwindToMore(_ segue:UIStoryboardSegue) {
        // segue *from* an MVC that was (directly or indirectly) presented by us
        // we can reach into the presented MVC, to retrieve data
        // can use with modally segued-to MVC

        // when returning from UserSettingsVC...
        // ...if we're ready to enrol, proceed to enroll?
        
        //let source = segue.sourceViewController
        // logger.log(.debug, "unwindToMainMenu: \(source)")
        
        // at the moment, we don't need to take any action here
    }
}









