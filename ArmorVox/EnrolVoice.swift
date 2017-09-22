//
//  EnrolVoice.swift
//  ArmorVox
//
//  Created by Rob Dixon on 03/08/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import Foundation

// MARK: - SpeakItem
// This represents a single item to speak...
// and whether it has been done
class SpeakItem: CustomStringConvertible {
    
    // MARK: - Class stuff...
    
    fileprivate static var numberSpelling = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
    
    fileprivate static func spelling(forDigit digit: Int) -> String {
        guard digit < 10 else {
            logger.log(.debug, "Unexpected digit: \(digit)")
            return ""
        }
        return numberSpelling[digit]
    }
    
    fileprivate static func spelling(forDigitString digitString: String) -> String {
        var retval = ""
        for d in digitString.characters {
            if let index = Int("\(d)"),
                index > 0 && index < 10 {
                retval.append("\(numberSpelling[index]) ")
            }
        }
        return retval
    }
    
    
    
    // MARK: - Instance
    
    let string: String
    let spelling: String
    var recordedSuccessfully = false
    
    // MARK: - init
    
    init(string: String) {
        self.string = string
        self.spelling = SpeakItem.spelling(forDigitString: string)
        self.recordedSuccessfully = false
    }
    
    var description: String {
        return "string: \(string), spelling: \(spelling) recordedSuccessfully: \(recordedSuccessfully)"
    }
    
    func copy() -> SpeakItem {
        let theCopy = SpeakItem(string: self.string)
        return theCopy
    }
}



// phraseUtterance
class PhraseUtterance {
    let name: String
    let utterance: Utterance
    
    init(name: String, utterance: Utterance) {
        self.name = name
        self.utterance = utterance
    }
}



// MARK: - EnrolVoice
class EnrolVoice {
    
    // 2017-08-04 NEW
    // Enrolment consists of:
    // 1) Phrase (currently, the email address), spoken 3 times
    // 2) 5 numbers
    
    var phrases: [SpeakItem] // must speak 3 times
    var phraseUtterances: [Utterance] = [] // as recorded, ready for enrolment
    fileprivate var phraseIndex = 0
    
    // numbers
    // we always use the same 5 numbers
    let numbers: [SpeakItem] = [
        SpeakItem(string: "4281 4281"),
        SpeakItem(string: "3798 3798"),
        SpeakItem(string: "5043 5043"),
        SpeakItem(string: "123456789"),
        SpeakItem(string: "987654321"),
    ]
    var numberUtterances: [Utterance] = [] // as recorded, ready for enrolment
    var numberPhrases: [String]? {
        var retval: [String] = []
        for number in numbers {
            retval.append(number.spelling)
        }
        return retval
    }
    fileprivate var numberIndex = 0
    
    var isAllRecordedSuccessfully: Bool {
        // if phrase and all numbers recordedSuccessfully
        for phrase in phrases {
            if !phrase.recordedSuccessfully {
                return false
            }
        }
        for number in numbers {
            if !number.recordedSuccessfully {
                return false
            }
        }
        return true
    }
    
    
    
    // MARK: - init
    
    init(phrase: SpeakItem) {
        self.phrases = [phrase, phrase.copy(), phrase.copy()] // must speak 3 times
        // Note: numbers are always the same
    }
    
    var nextNumber: SpeakItem? {
        return numberIndex < numbers.count ? numbers[numberIndex] : nil
    }
    
    var nextPhrase: SpeakItem? {
        return phraseIndex < phrases.count ? phrases[phraseIndex] : nil
    }
    
    func doneCurrentPhrase(success: Bool) {
        if let current = nextPhrase {
            current.recordedSuccessfully = success
            phraseIndex += 1
        } else {
            logger.log(.error, "No current phrase")
        }
    }
    
    func doneCurrentNumber(success: Bool) {
        if let current = nextNumber {
            current.recordedSuccessfully = success
            numberIndex += 1
        } else {
            logger.log(.error, "No current number")
        }
    }
}










