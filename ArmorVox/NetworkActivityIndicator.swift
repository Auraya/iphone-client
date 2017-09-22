//
//  NetworkActivityIndicator.swift
//  RycoteGPS
//
//  Created by Rob Dixon on 03/10/2016.
//  Copyright © 2016 Auraya Systems. All rights reserved.
//

import UIKit

class NetworkActivityIndicator {
    // While there is network activity, we show the status bar network activity indicator
    // To allow for multiple sources of activity, we have to keep count of how many are in progress
    // The count is held in a global singleton
    // This object allows the count to be incremented or decremented
    // This object also takes responsibility for showing/hiding the status bar network activity indicator
    
    fileprivate var count = 0 // counts how many network activities are in progress
    
    static let sharedActivity = NetworkActivityIndicator()
    
    func increment() {
        if count == 0 { // activity started
            DispatchQueue.main.async { () -> Void in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
        }
        count += 1
    }
    
    func decrement() {
        if count > 0 {
            count -= 1
        } else {
            logger.log(.warning, "attempted to decrement RSSActivityCounter below 0")
        }
        if count == 0 { // activity ended
            DispatchQueue.main.async { () -> Void in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
    }
}
