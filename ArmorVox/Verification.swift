//
//  Verification.swift
//  ArmorVox
//
//  Created by Rob Dixon on 04/08/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import Foundation

// MARK: - VerificationType
// Currently, we allow two types of verification
// NOTE: this is stored in AppSettings.shared.verificationType
enum VerificationType: Int, CustomStringConvertible {
    case phrase = 0,
    numbers
    
    var description: String {
        switch self {
        case .phrase:
            return "Phrase"
        case .numbers:
            return "Numbers"
        }
    }
    
    var speechItemType: SpeechItemType {
        switch self {
        case .phrase:
            return SpeechItemType.phrase
        case .numbers: // NOTE: type is not used!
            return SpeechItemType.id
        }
    }
    
    static func forSpeechItemType(_ speechItemType: SpeechItemType) -> VerificationType {
        switch speechItemType {
        case .phrase:
            return .phrase
        case .textPrompted:
            return .numbers
        default:
            return .phrase
        }
    }
}



// MARK: - Verification
class Verification {
    
    static func randomNumberString() -> String {
        // Generate a random number, to use in verification
        // the generated number is a set of 4 unique digits, repeated, with a space separator
        var sourceDigits = [1, 2, 3, 4, 5, 6, 7, 8, 9] // Note: omit 0 (due to ambiguous pronounciation)
        var numberString = ""
        for _ in 1...4 {
            let index = Int(arc4random_uniform(UInt32(sourceDigits.count))) // // gives 0 to (count - 1)
            let digit = sourceDigits.remove(at: index)
            numberString.append("\(digit)")
        }
        numberString.append(" \(numberString)")
        return numberString
    }
}
