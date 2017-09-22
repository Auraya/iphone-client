//
//  ArmorVox.swift
//  ArmorVoxTest
//
//  Created by Rob Dixon on 25/07/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import Foundation

// ArmorVox
// This class is used for the high-level ArmorVox API parameters
// Note that these may change during testing, and between testing and production
class ArmorVox {

    // apiServerRootURLString
    // This is the address of the ArmorVox API server
    static let apiServerRootURLString = "http://52.65.165.8:9006/v5/"
    
    // sessionID
    static let sessionID: SessionID = "iphone_demo"
}



// MARK: - API supporting definitions

public typealias SessionID = String // max 100 chars

public typealias UserID = Int // max 10 digits

public typealias Utterance = URL // ...of .wav sound file

enum SpeechItemType: Int, CustomStringConvertible {
    case id = 1,
    telephoneNumber,
    userName,
    pin,
    date,
    hint,
    digits,
    phrase, // 8
    textIndependent = 10,
    textPrompted = 11
    
    // NOTE: The recommended items based on speech consistency are ID (1) and phrase (8).
    
    var description: String {
        switch self {
        case .id:
            return "ID"
        case .telephoneNumber:
            return "Telephone no"
        case .userName:
            return "Username"
        case .pin:
            return "PIN"
        case .date:
            return "Date"
        case .hint:
            return "Hint"
        case .digits:
            return "Digits"
        case .phrase:
            return "Phrase"
        case .textIndependent:
            return "Text-independent"
        case .textPrompted:
            return "Text-prompted"
        }
    }
}

enum PhraseEnrolmentVariation: Int, CustomStringConvertible {
    // For Enrolment with Type == .phrase (8)...
    // We can use these variations, for different phrases
    // This enum is compatible with use in a SegmentedControl
    case emailAddress = 0,
    homeAddress,
    fullName,
    secretPhrase
    
    var description: String {
        switch self {
        case .emailAddress:
            return "Email Address"
        case .homeAddress:
            return "Home Address"
        case .fullName:
            return "Full Name"
        case .secretPhrase:
            return "Secret Phrase"
        }
    }
}



// API return types

// Condition
enum Condition: String {
    case enrolled, // ID is enrolled
    not_enrolled, // ID is not enrolled
    good, // success
    repeatall, // bad voiceprint
    unsure, // result below Threshold 1 but above Threshold 2
    qafailed, // problem with voice sample
    fail,
    error // ID is not within allocated range, date is expired, database failed, or any other errors
    
    var description: String {
        return self.rawValue.uppercased()
    }
}

// Extra
public typealias Extra = String // an error message, if condition is .fail or .error



// MARK: - ArmorVoxAPIResponse

// ArmorVoxAPIResponse
// This object is created and returned by the API calls
class ArmorVoxAPIResponse: CustomStringConvertible {
    let userID: UserID? // Int
    let condition: Condition? // enum
    let extra: Extra? // String
    
    init(userID: UserID?, condition: Condition?, extra: Extra?) {
        self.userID = userID
        self.condition = condition
        self.extra = extra
    }
    
    var description: String {
        let conditionString = condition != nil ? condition!.description : ""
        return "userID: \(userID ?? -1), condition: \(conditionString), extra: \(extra ?? "")"
    }
}






