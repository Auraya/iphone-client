//
//  XMLProcessing.swift
//  Snippets
//
//  Created by Rob Dixon on 17/05/2017.
//  Copyright © 2017 Rob Dixon. All rights reserved.
//

import Foundation

// ArmorVoxXMLParser



// MARK: - Data
class ArmorVoxXMLParser: NSObject {

    var parsedResponse: ArmorVoxAPIResponse? // this is what we are going to build
    
    fileprivate var inputBuffer = ""
    
    // vars used to build the item while parsing...
    fileprivate var sessionIDString: String?
    fileprivate var userIDString: String?
    fileprivate var conditionString: String?
    fileprivate var extraString: String?
    fileprivate var utteranceString: String?
}



// MARK: - Parse
extension ArmorVoxXMLParser {
    
    func parse(url: URL) {
        // parse the given url
        if let parser = XMLParser(contentsOf: url) {
            parser.delegate = self
            parser.parse()
        }
    }
    
    func parse(data: Data) {
        // parse the given data
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
    }
}



// MARK: - XMLParserDelegate
extension ArmorVoxXMLParser: XMLParserDelegate {
    
    func parserDidStartDocument(_ parser: XMLParser) {
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        let userID = userIDString != nil ? UserID(userIDString!) : nil
        let condition = conditionString != nil ? Condition(rawValue: conditionString!.lowercased()) : nil
        let extra = extraString as Extra?
        parsedResponse = ArmorVoxAPIResponse(userID: userID, condition: condition, extra: extra)
        //logger.log(.debug, "userIDString: \(userIDString), conditionString: \(conditionString), extraString: \(extraString)")
        //logger.log(.debug, "userID \(userID), condition \(condition), extra \(extra)")
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        // foundCharacters
        // trim white-space, and add to inputBuffer
        let inString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if inString.characters.count > 0 {
            inputBuffer.append(inString)
        }
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        // we're starting to parse a new element... what type is it?
        switch elementName {
        case "var":
            // Note: all the data we require is contained within the "var" tag
            if let name = attributeDict["name"], let expr = attributeDict["expr"] {
                // trim ' character from beginning and end of parsed string
                let exprTrimmed = expr.trimmingCharacters(in: CharacterSet(charactersIn: "'"))
                switch name {
                case "Session":
                    sessionIDString = exprTrimmed
                case "UserID":
                    userIDString = exprTrimmed
                case "Condition":
                    conditionString = exprTrimmed
                case "Extra":
                    extraString = exprTrimmed
                case "Utterance":
                    utteranceString = exprTrimmed
                default:
                    // not used, ignore
                    //logger.log(.debug, "name: \(name), expr: \(expr)")
                    break
                }
            }
        default:
            // not "var", ignore
            //logger.log(.debug, "\(elementName): \(attributeDict)")
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        // reached end of element...
        // Note: we've already got the required information, from didStartElement
        inputBuffer = ""
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        // Sent by a parser object to its delegate when it encounters a fatal error
        // NOTE: could add more diagnostic logging here...
        logger.log(.error, "\(parseError.localizedDescription)")
    }
}



// MARK: - utility methods...
extension ArmorVoxXMLParser {
    
    func replaceHtmlEntities(data: Data) -> Data? {
        if let htmlCode = String(data: data, encoding: String.Encoding.utf8) {
            var tempString = htmlCode
            tempString = tempString.replacingOccurrences(of: "[&hellip;]", with: "…")
            tempString = tempString.replacingOccurrences(of: "&nbsp;", with: " ")
            tempString = tempString.replacingOccurrences(of: "&amp;", with: "&")
            let finalData = tempString.data(using: String.Encoding.utf8)
            return finalData
        }
        return nil
    }
    
    func parser(parser: XMLParser, resolveExternalEntityName name: String, systemID: String?) -> Data? {
        logger.log(.debug, "name: \(name), systemID: \(systemID ?? "")")
        if name == "hellip" {
            return "...".data(using: String.Encoding.utf8)
        }
        return nil
    }
    
    func parser(parser: XMLParser, foundInternalEntityDeclarationWithName name: String, value: String?) {
        logger.log(.debug, "")
    }
    
    func parser(parser: XMLParser, foundExternalEntityDeclarationWithName name: String, publicID: String?, systemID: String?) {
        logger.log(.debug, "")
    }
    
    func parser(parser: XMLParser, foundUnparsedEntityDeclarationWithName name: String, publicID: String?, systemID: String?, notationName: String?) {
        logger.log(.debug, "")
    }
}
