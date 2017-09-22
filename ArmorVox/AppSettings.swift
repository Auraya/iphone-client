//
//  AppSettings.swift
//  ArmorVox
//
//  Created by Rob Dixon on 04/08/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import UIKit

/*
 class AppSettings
 We use a global singleton shared
 Strings for all keys are stored in the struct AppSettingsKeys
 */
class AppSettings: CustomStringConvertible {
    
    // MARK: - shared
    
    static let shared = AppSettings() // Global Singleton to store App Settings
    
    
    
    // MARK: - Constants
    
    fileprivate struct AppSettingsKeys { // struct to store keys for the various settings
        static let verificationTypeKey = "verificationTypeKey"
    }
    
    
    
    // MARK: - Properties (these are the actual settings)
    
    var verificationType: VerificationType {
        get {
            let value = UserDefaults.standard.integer(forKey: AppSettingsKeys.verificationTypeKey) // 0 if it doesn't exist
            if let type = VerificationType(rawValue: value) {
                return type
            }
            return .phrase
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: AppSettingsKeys.verificationTypeKey)
        }
    }
    
    var iconWidthConstraintConstant: CGFloat {
        get {
            if UIScreen.main.bounds.size.width == 320 {
                return 40.0
            }
            return 60.0
        }
    }
    
    var description: String {
        return "verificationType: \(verificationType)"
    }
}





