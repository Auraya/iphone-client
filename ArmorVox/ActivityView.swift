//
//  ActivityView.swift
//  Snippets
//
//  Created by Rob Dixon on 04/05/2016.
//  Copyright © 2016 Auraya Systems. All rights reserved.
//

import UIKit

extension UIActivityIndicatorView {
    
    func addTo(_ view: UIView) {
        // set defaults, and add it to the given view
        self.color = UIColor.lightGray
        view.addSubview(self)
    }
    
    func positionAtCenter(_ view: UIView) {
        // position at center of given view
        self.frame.origin = CGPoint(x: view.frame.midX - (self.frame.size.width / 2), y: view.frame.midY - (self.frame.size.height / 2))
    }
    
}



// MARK: - usage example:

class classThatShowsAnActivityIndicator_ViewController: UIViewController {
    
    var contentLoaded = false {
        didSet {
            if contentLoaded {
                NetworkActivityIndicator.sharedActivity.decrement()
                setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    
    fileprivate var spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge) // show retrieval activity
    

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // add the activity spinner
        spinner.addTo(view)
    }
    
    override func viewDidLayoutSubviews() {
        // autolayout has happened...
        super.viewDidLayoutSubviews()
        spinner.positionAtCenter(view) // position spinner at center of (some) view
    }
    
    
    func someFunc_ActivityStart() {
        spinner.startAnimating() // activity started
    }
    
    func someFunc_ActivityStop() {
        spinner.stopAnimating() // activity stopped
    }

}
