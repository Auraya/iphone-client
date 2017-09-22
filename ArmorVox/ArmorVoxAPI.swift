//
//  ArmorVoxAPI.swift
//  ArmorVoxTest
//
//  Created by Rob Dixon on 20/07/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import Foundation


// MARK: - API supporting definitions

fileprivate typealias APIParamsType = Dictionary<String, String>





// API parameters

fileprivate enum apiParameter: String {
    case userID,
    sessionID,
    type,
    utterance,
    utterance1, // audio file
    utteranceN, // audio file (array?)
    utteranceN2, // audio file (array?)
    phrase1, // phrase
    phraseN, // phrases
    vocabulary, // encrypted vocabulary file (only supported value is en_us_v_2.0)
    mode, // enrol or verify
    list // list of blacklisted speakers (comma separated)
    
    var description: String {
        return self.rawValue.capitalized
    }
}







// MARK: - ArmorVoxAPI

class ArmorVoxAPI {
    
    // MARK: - Data
    
    fileprivate static let version = 5
    
    
    
    
    
    // MARK: - API Calls
    
    static func checkEnrolled(sessionID: SessionID, userID: UserID, type: SpeechItemType, completion: @escaping (_ response: ArmorVoxAPIResponse?) -> Void) {
        // Check to see if an ID number has already been enrolled
        let urlString = ArmorVox.apiServerRootURLString + "checkEnrolled"
        guard let url = URL(string: urlString) else {
            logger.log(.error, "Invalid API url: \(urlString)")
            completion(nil)
            return
        }
        let params: APIParamsType = ["UserID": "\(userID)", "Type": "\(type.rawValue)", "SessionID": sessionID as String]
        post(apiURL: url, params: params) { (response: ArmorVoxAPIResponse?) in
            completion(response) // pass API response back to caller
        }
    }
    
    static func deleteUser(sessionID: SessionID, userID: UserID, type: SpeechItemType, completion: @escaping (_ response: ArmorVoxAPIResponse?) -> Void) {
        // Deletes all data associated with a particular ID and a particular speech item.
        let urlString = ArmorVox.apiServerRootURLString + "deleteUser"
        guard let url = URL(string: urlString) else {
            logger.log(.error, "Invalid API url: \(urlString)")
            completion(nil)
            return
        }
        let params: APIParamsType = ["UserID": "\(userID)", "Type": "\(type.rawValue)", "SessionID": sessionID as String]
        post(apiURL: url, params: params) { (response: ArmorVoxAPIResponse?) in
            completion(response) // pass API response back to caller
        }
    }

    static func auraya_enrol(sessionID: SessionID, userID: UserID, type: SpeechItemType, utterances: [Utterance], completion: @escaping (_ response: ArmorVoxAPIResponse?) -> Void) {
        // Submit three utterances for enrolment
        let urlString = ArmorVox.apiServerRootURLString + "auraya_enrol"
        guard let url = URL(string: urlString) else {
            logger.log(.error, "Invalid API url: \(urlString)")
            completion(nil)
            return
        }
        guard utterances.count == 3 else {
            logger.log(.error, "Expected 3 utterances, got: \(utterances.count)")
            completion(nil)
            return
        }
        let params: APIParamsType = ["UserID": "\(userID)", "Type": "\(type.rawValue)", "SessionID": sessionID as String]
        
        post(apiURL: url, params: params, utterances: utterances) { (response: ArmorVoxAPIResponse?) in
            completion(response) // pass API response back to caller
        }
    }

    static func text_prompted_enrol(sessionID: SessionID, userID: UserID, utterances: [Utterance], phrases: [String], completion: @escaping (_ response: ArmorVoxAPIResponse?) -> Void) {
        // Submit utterances for enrolment
        let urlString = ArmorVox.apiServerRootURLString + "text_prompted_enrol"
        guard let url = URL(string: urlString) else {
            logger.log(.error, "Invalid API url: \(urlString)")
            completion(nil)
            return
        }
        guard utterances.count == 5 else {
            logger.log(.error, "Expected 5 utterances, got: \(utterances.count)")
            completion(nil)
            return
        }
        let params: APIParamsType = ["UserID": "\(userID)", "SessionID": sessionID as String]
        
        post(apiURL: url, params: params, utterances: utterances, phrases: phrases) { (response: ArmorVoxAPIResponse?) in
            completion(response) // pass API response back to caller
        }
    }

    static func aurayaVerify(sessionID: SessionID, userID: UserID, type: SpeechItemType, utterance: Utterance, completion: @escaping (_ response: ArmorVoxAPIResponse?) -> Void) {
        // Submit an utterance for verification
        let urlString = ArmorVox.apiServerRootURLString + "auraya_verify"
        guard let url = URL(string: urlString) else {
            logger.log(.error, "Invalid API url: \(urlString)")
            completion(nil)
            return
        }
        let params: APIParamsType = ["UserID": "\(userID)", "Type": "\(type.rawValue)", "SessionID": sessionID as String]
        post(apiURL: url, params: params, utterances: [utterance]) { (response: ArmorVoxAPIResponse?) in
            completion(response)
        }
    }
    
    static func textPromptedVerify(sessionID: SessionID, userID: UserID, utterance: Utterance, phrase: String, completion: @escaping (_ response: ArmorVoxAPIResponse?) -> Void) {
        // Submit utterance for verification
        let urlString = ArmorVox.apiServerRootURLString + "text_prompted_verify"
        guard let url = URL(string: urlString) else {
            logger.log(.error, "Invalid API url: \(urlString)")
            completion(nil)
            return
        }
        let params: APIParamsType = ["UserID": "\(userID)", "SessionID": sessionID as String]
        
        post(apiURL: url, params: params, utterances: [utterance], phrases: [phrase]) { (response: ArmorVoxAPIResponse?) in
            completion(response) // pass API response back to caller
        }
    }
 
    
    
    
    
    // MARK: API POST
    
    fileprivate static func post(apiURL: URL, params: APIParamsType, utterances: [Utterance]? = nil, phrases: [String]? = nil, completion: @escaping (_ response: ArmorVoxAPIResponse?) -> Void) { // (_ json: Dictionary<String, Any>?) -> Void) {
        // The Auraya API implementation supports web request/response patterns.
        // The server will accept API commands sent using ‘POST’ with a content type of Multipart/Form-Data.
        
        //logger.log(.debug, "params: \(params)\n")
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        
        // boundary
        // A data boundary has to be set: the data boundary is a piece of random string that should not in any occasion whatsoever re-appear within the data being sent to the server as server uses it to figure out where individual data sets begin and end.
        let boundaryString = "Boundary-L7bOhk-cLYo14N7VAT_2qNS0pvioFWmlLx"
        
        // Content-Type
        let contentType = "multipart/form-data; boundary=" + boundaryString
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        // httpBody
        var bodyData = Data()
        for param in params {
            bodyData.append("--\(boundaryString)\r\n".data(using: .utf8) ?? Data())
            bodyData.append("Content-Disposition: form-data; name=\"\(param.key)\"\r\n".data(using: .utf8) ?? Data())
            bodyData.append("Content-Type: text/plain\r\n".data(using: .utf8) ?? Data())
            bodyData.append("Content-Transfer-Encoding: 8bit\r\n\r\n".data(using: .utf8) ?? Data())
            bodyData.append("\(param.value)\r\n".data(using: .utf8) ?? Data())
        }
        
        // add phrase(s) (if present)
        if let phrases = phrases {
            // add the phrases
            for i in 0..<phrases.count { //
                let phrase = phrases[i]
                let phraseName = phrases.count == 1 ? "Phrase" : "Phrase\(i+1)"
                bodyData.append("--\(boundaryString)\r\n".data(using: .utf8) ?? Data())
                bodyData.append("Content-Disposition: form-data; name=\"\(phraseName)\"\r\n".data(using: .utf8) ?? Data())
                bodyData.append("Content-Type: text/plain\r\n".data(using: .utf8) ?? Data())
                bodyData.append("Content-Transfer-Encoding: 8bit\r\n\r\n".data(using: .utf8) ?? Data())
                bodyData.append("\(phrase)\r\n".data(using: .utf8) ?? Data())
            }
        }
        
        // for testing
        /*
        if let httpBody = request.httpBody {
            let bodyString = String(data: httpBody, encoding: .utf8)
            logger.log(.debug, "request: \n\(request.allHTTPHeaderFields ?? [:])\n\tbodyString: \n\(bodyString ?? "")\n")
        }
        */

        // add utterance(s) (if present)
        if let utterances = utterances {
            // add the utterances
            for i in 0..<utterances.count { // url of voice data file
                let utterance = utterances[i]
                let utteranceName = utterances.count == 1 ? "Utterance" : "Utterance\(i+1)"
                let utteranceData: Data
                do {
                    utteranceData = try Data(contentsOf: utterance)
                } catch {
                    utteranceData = Data()
                }
                
                bodyData.append("--\(boundaryString)\r\n".data(using: .utf8) ?? Data())
                bodyData.append("Content-Disposition: form-data; name=\"\(utteranceName)\"\r\n".data(using: .utf8) ?? Data())
                bodyData.append("Content-Type: application/octet-stream\r\n".data(using: .utf8) ?? Data())
                bodyData.append("Content-Transfer-Encoding: binary\r\n\r\n".data(using: .utf8) ?? Data())
                bodyData.append(utteranceData)
                bodyData.append("\r\n".data(using: .utf8) ?? Data())
            }
        }
        
        // end
        bodyData.append("--\(boundaryString)--\r\n".data(using: .utf8) ?? Data())
        request.httpBody = bodyData
        
        NetworkActivityIndicator.sharedActivity.increment()
        
        //let bodyString = String(data: request.httpBody!, encoding: .utf8)
        //logger.log(.debug, "request: \n\(request.allHTTPHeaderFields ?? [:])\n\tbodyString: \n\(bodyString ?? "")\n")
        
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil {
                logger.log(.error, "\(error!.localizedDescription)")
            }
            DispatchQueue.main.async { // Update the UI with the results of the above
                if let data = data {
                    // we've got data... parse the xml
                    if let dataString = String(data: data, encoding: String.Encoding.utf8) { logger.log(.debug, "got data: \n\(dataString)\n") }
                    
                    // parse returned xml,, create an ArmorVoxAPIResponse object, and call completion handler with the result
                    let parser = ArmorVoxXMLParser()
                    if let cleanedData = parser.replaceHtmlEntities(data: data) {
                        parser.parse(data: cleanedData)
                        let response = parser.parsedResponse
                        DispatchQueue.main.async {
                            // call UI functions with the results of the above
                            completion(response)
                        }
                    }

                } else { // no data
                    completion(nil)
                }
            }
            NetworkActivityIndicator.sharedActivity.decrement()
        }
        task.resume()
    }
}




















