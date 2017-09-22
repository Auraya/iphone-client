//
//  UserSettings.swift
//  ArmorVox
//
//  Created by Rob Dixon on 04/08/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import Foundation

enum UserStatus: Int, CustomStringConvertible {
    case notReadyToEnrol, readyToEnrol, enrolled
    
    var description: String {
        switch self {
        case .notReadyToEnrol:
            return "Not ready to enrol"
        case .readyToEnrol:
            return "Ready to enrol"
        case .enrolled:
            return "Enrolled"
        }
    }
}

/*
 class UserSettings
 We use a global singleton shared
 Strings for all keys are stored in the struct UserSettingsKeys
 */
class UserSettings: CustomStringConvertible {
    
    // MARK: - shared
    
    static let shared = UserSettings() // Global Singleton to store User Settings
    
    
    
    // MARK: - Constants
    
    fileprivate struct UserSettingsKeys { // struct to store keys for the various settings
        static let nameKey = "nameKey"
        static let phoneNumberKey = "phoneNumberKey"
        static let phraseEnrolmentStatusKey = "phraseEnrolmentStatusKey"
        static let numbersEnrolmentStatusKey = "numbersEnrolmentStatusKey"
        static let phraseEnrolmentVariationKey = "phraseEnrolmentVariationKey"
    }
    
    
    
    // MARK: - Properties (these are the actual settings)
    
    var userIDString: String? {
        // create from phone number
        if var numberString = phoneNumber,
            numberString != "" {
            // validation...
            numberString = numberString.replacingOccurrences(of: " ", with: "")
            numberString = numberString.replacingOccurrences(of: "*", with: "")
            numberString = numberString.replacingOccurrences(of: "#", with: "")
            numberString = numberString.replacingOccurrences(of: ",", with: "")
            numberString = numberString.replacingOccurrences(of: ";", with: "")
            numberString = numberString.replacingOccurrences(of: "+", with: "")
            if let number = Int(numberString) {
                var cleanedString = "\(number)"
                if cleanedString.characters.count > 7 {
                    let startIndex = cleanedString.index(cleanedString.endIndex, offsetBy: -7)
                    cleanedString = cleanedString.substring(from: startIndex)
                    if let trimmedNumber = Int(cleanedString) {
                        cleanedString = "\(trimmedNumber)"
                        return cleanedString
                    }
                }
            }
        }
        return nil
    }

    var userID: UserID? {
        if let idString = userIDString,
            idString != "",
            let idInt = Int(idString),
            idInt != 0 {
            return idInt
        }
        return nil
    }
    
    var name: String? {
        get {
            return UserDefaults.standard.string(forKey: UserSettingsKeys.nameKey) // nil if it doesn't exist
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserSettingsKeys.nameKey)
            updateStatus()
        }
    }
    
    var phoneNumber: String? {
        get {
            return UserDefaults.standard.string(forKey: UserSettingsKeys.phoneNumberKey) // nil if it doesn't exist
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserSettingsKeys.phoneNumberKey)
            updateStatus()
        }
    }
    
    var phraseEnrolmentVariation : PhraseEnrolmentVariation {
        get {
            let value = UserDefaults.standard.integer(forKey: UserSettingsKeys.phraseEnrolmentVariationKey) // 0 if it doesn't exist
            if let variation = PhraseEnrolmentVariation(rawValue: value) {
                return variation
            }
            return .emailAddress
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: UserSettingsKeys.phraseEnrolmentVariationKey)
        }
    }

    // NOTE:
    // we store an enrolmentStatus for each verificationType
    // currently phrase, numbers
    var phraseEnrolmentStatus: UserStatus  {
        get {
            let value = UserDefaults.standard.integer(forKey: UserSettingsKeys.phraseEnrolmentStatusKey) // 0 if it doesn't exist
            if let result = UserStatus(rawValue: value) {
                return result
            }
            return .notReadyToEnrol
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: UserSettingsKeys.phraseEnrolmentStatusKey)
        }
    }
    
    var numbersEnrolmentStatus: UserStatus  {
        get {
            let value = UserDefaults.standard.integer(forKey: UserSettingsKeys.numbersEnrolmentStatusKey) // 0 if it doesn't exist
            if let result = UserStatus(rawValue: value) {
                return result
            }
            return .notReadyToEnrol
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: UserSettingsKeys.numbersEnrolmentStatusKey)
        }
    }
    
    // NOTE: combine the enrolment status fields, to give an overallStatus
    var overallStatus: UserStatus {
        get {
            if phraseEnrolmentStatus == .enrolled && numbersEnrolmentStatus == .enrolled {
                return .enrolled
            }
            if phraseEnrolmentStatus == .notReadyToEnrol || numbersEnrolmentStatus == .notReadyToEnrol {
                return .notReadyToEnrol
            }
            return .readyToEnrol
        }
        set {
            phraseEnrolmentStatus = newValue
            numbersEnrolmentStatus = newValue
        }
    }
    
    // NOTE: sometimes we need to know if *any* verification method meets a criteria
    var anyStatus: UserStatus {
        get {
            if phraseEnrolmentStatus == .enrolled || numbersEnrolmentStatus == .enrolled {
                return .enrolled
            }
            if phraseEnrolmentStatus == .readyToEnrol || numbersEnrolmentStatus == .readyToEnrol {
                return .readyToEnrol
            }
            return .notReadyToEnrol
        }
    }
    
    // NOTE:
    // return the status, for the currently selected verificationType
    func status(forVerificationType verificationType: VerificationType) -> UserStatus {
        switch verificationType {
        case .phrase:
            return phraseEnrolmentStatus
        case .numbers:
            return numbersEnrolmentStatus
        }
    }
    
    func setStatus(_ status: UserStatus, forVerificationType verificationType: VerificationType) {
        switch verificationType {
        case .phrase:
            phraseEnrolmentStatus = status
        case .numbers:
            numbersEnrolmentStatus = status
        }
    }
    
    fileprivate func updateStatus() {
        if phraseEnrolmentStatus != .enrolled {
            phraseEnrolmentStatus = phoneNumber == nil ? .notReadyToEnrol : .readyToEnrol
        }
        if numbersEnrolmentStatus != .enrolled {
            numbersEnrolmentStatus = phoneNumber == nil ? .notReadyToEnrol : .readyToEnrol
        }
    }
    
    var isReadyToEnrol: UserStatus {
        return phoneNumber == nil ? .notReadyToEnrol : .readyToEnrol
    }
    
    var description: String {
        return "phone number: \(phoneNumber ?? "<not set>"), phraseEnrolmentVariation: \(phraseEnrolmentVariation), phraseEnrolmentStatus: \(phraseEnrolmentStatus), numbersEnrolmentStatus: \(numbersEnrolmentStatus)"
    }
}
