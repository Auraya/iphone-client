//
//  MoreViewController.swift
//  ArmorVox
//
//  Created by Rob Dixon on 27/07/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import UIKit

class MoreViewController: UIViewController {

    // MARK: - UI
    
    @IBOutlet weak var tableView: UITableView!
    
    

    // MARK: - Data
    
    var tableData: [MoreListitem] = [
        MoreListitem(image: nil, text: "New! Enrol your voice", segueID: "ShowEnrol"),
        MoreListitem(image: nil, text: "Test Voice Recording", segueID: "ShowVoiceTest"),
        MoreListitem(image: nil, text: "API Tests", segueID: "ShowAPITests"),
        MoreListitem(image: nil, text: "User Settings", segueID: "ShowUserSettings"),
        MoreListitem(image: nil, text: "App Settings", segueID: "ShowAppSettings")
        ]

    
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView(frame: .zero) // prevents extra empty rows, below data 
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // just before view appears on screen
        super.viewWillAppear(animated)
        // MoreVC doesn't show the navigationBar
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.isHidden = false
    }
    
    
    
    // MARK: - Action


    
    // MARK: - Methods


    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // NOTE: destination outlets are not set, when this is called
        
        // deselect selected tableView row
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        if let identifier = segue.identifier {
            switch identifier {
                
            case "ShowEnrol":
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
                
            case "ShowVoiceTest":
                var destination = segue.destination
                if let navCon = segue.destination as? UINavigationController {
                    destination = navCon.visibleViewController! // this lets us cope with the case where our vc is embedded in a navigation controller
                }
                if let destinationVC = destination as? VoiceTestViewController {
                    // retrieve info from sender (as it's correct class)
                    // ... and use it to set up the destinationVC
                    // NOTE: this is happening BEFORE outlets get set!
                    // EnrolVoiceVC hides the TabBar...
                    destinationVC.hidesBottomBarWhenPushed = true
                    
                } else { // unexpected class of destinationViewController
                    logger.log(.warning, "Unexpected segue destination: \(segue.destination)")
                }
             
            case "ShowAPITests":
                var destination = segue.destination
                if let navCon = segue.destination as? UINavigationController {
                    destination = navCon.visibleViewController! // this lets us cope with the case where our vc is embedded in a navigation controller
                }
                if let _ = destination as? APITestsViewController {
                    // retrieve info from sender (as it's correct class)
                    // ... and use it to set up the destinationVC
                    // NOTE: this is happening BEFORE outlets get set!
                    
                } else { // unexpected class of destinationViewController
                    logger.log(.warning, "Unexpected segue destination: \(segue.destination)")
                }
                
            case "ShowUserSettings", "ShowAppSettings":
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
        
        //let source = segue.sourceViewController
        // logger.log(.debug, "unwindToMainMenu: \(source)")
        
        // at the moment, we don't need to take any action here
    }
}



extension MoreViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - tableView, REQUIRED
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { // DataSource
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { // DataSource
        let cell = tableView.dequeueReusableCell(withIdentifier: "MoreTableViewCell", for: indexPath)
        
        // retrieve the corresponding data model object
        let listItem = tableData[indexPath.row]
        
        // configure the cell
        cell.textLabel?.text = listItem.text
        
        return cell
    }
    
    // MARK: - tableView, SELECTION
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { // Delegate
        // Take some action based on information about the Model corresponding to indexPath.row in indexPath.section
        let listItem = tableData[indexPath.row]
        performSegue(withIdentifier: listItem.segueID, sender: self)
    }
}





