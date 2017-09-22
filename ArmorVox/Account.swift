//
//  Account.swift
//  ArmorVoxTest
//
//  Created by Rob Dixon on 21/07/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import Foundation



// MyAccounts
// Represents a person, and their accounts and details
class MyAccounts {
    
    var familyName: String
    var givenName: String
    var accounts: [Account]
    var totalCreditBalance: Float
    
    init(familyName: String, givenName: String, accounts: [Account], totalCreditBalance: Float = 0) {
        self.familyName = familyName
        self.givenName = givenName
        self.accounts = accounts
        self.totalCreditBalance = totalCreditBalance
    }
    
    static func defaultMyAccounts() -> MyAccounts {
        let accounts = Account.defaultAccounts()
        let myAccounts = MyAccounts(familyName: "Young", givenName: "Jennifer", accounts: accounts, totalCreditBalance: 15940.50)
        return myAccounts
    }
}



// Account
// Represents a single bank account
class Account {
    
    let name: String
    let number: String
    let code: String
    var availableBalance: Float
    let currentBalance: Float
    
    init(name: String, number: String, code: String, availableBalance: Float = 0, currentBalance: Float = 0) {
        self.name = name
        self.number = number
        self.code = code
        self.availableBalance = availableBalance
        self.currentBalance = currentBalance
    }
    
    static func defaultAccounts() -> [Account] {
        let personalAccount = Account(name: "Personal Account", number: "#5543", code: "658-255-78-586-5543", availableBalance: 3245.10, currentBalance: 3245.10)
        let savingsAccount = Account(name: "Savings Account", number: "#5587", code: "658-255-78-586-5587", availableBalance: 200.50, currentBalance: 7355.60)
        return [personalAccount, savingsAccount]
    }
    
    static func jakesAccount() -> Account {
        return Account(name: "Jake", number: "BSB 586-554", code: "58-425-3625")
    }
}



// Transfer
// Represents a transfer between accounts
class Transfer {
    let transferAmount: TransferAmount
    let fromAccount: Account
    let toAccount: Account
    let payWhen: PayWhen
    
    init(transferAmount: TransferAmount, fromAccount: Account, toAccount: Account, payWhen: PayWhen) {
        self.transferAmount = transferAmount
        self.fromAccount = fromAccount
        self.toAccount = toAccount
        self.payWhen = payWhen
    }
}

// TransferTerms
class TransferTerms {
    let terms = "An incorrect BSB or Account Number may result in your money being paid to the wrong person and you may not get your money back.\n\nPayments made before 6 pm AEST/ AEDT should be received by bank accounts within 1 to 2 business days."
}

// AuthorizeInstructions
class AuthorizeInstructions {
    let text = "AUTHORIZE PAYMENT.\n\nPlease touch the microphone and say"
}

// SpeakText
class SpeakText {
    let text: String
    
    init(text: String) {
        self.text = text
    }
}


// TransferAmount
// Represents a transfer amount
class TransferAmount: CustomStringConvertible {
    var amount: Float = 0
    var desc: String = ""
    var isValid: Bool {
        return amount != 0
    }
    var description: String {
        return "amount: \(amount), description: \(desc)"
    }
}


// PayWhen
enum PayWhen {
    case today
    var description: String {
        return "Today"
    }
}
// TransferPayWhen
// Represents a transfer between accounts
class TransferPayWhen: CustomStringConvertible {
    let payWhen: PayWhen = .today

    var description: String {
        return payWhen.description
    }
}



extension Float {
    var currencyString: String {
        return String(format: "$%.2f", self)
    }
}
