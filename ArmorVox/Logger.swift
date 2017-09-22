//
//  Logger.swift
//  Snippets
//
//  Created by Rob Dixon on 02/05/2016.
//  Modified by Rob Dixon on 2016-05-09
//  Copyright © 2016 Rob Dixon. All rights reserved.
//

// From Ole Bergmann
// See http://oleb.net/blog/2016/05/default-arguments-in-protocols/

import Foundation

let logger: Logger = PrintLogger(minimumLogLevel: .verbose) // logLevels >= this will be logged
// to use... logger.log(.error, "An error occurred")



enum LogLevel: Int {
    case minimal = 0
    case verbose = 1
    case debug = 2
    case info = 3
    case warning = 4
    case error = 5
}

extension LogLevel: Comparable {}

func <(lhs: LogLevel, rhs: LogLevel) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

protocol Logger {
    /// Writes a log entry. Types that
    /// conform to `Logger` must implement
    /// this to perform their work.
    ///
    /// - Important: Clients of `Logger`
    ///   should never call this method.
    ///   Always call `log(_:,_:)`.
    func writeLogEntry(
        _ logLevel: LogLevel,
        _ message: @autoclosure () -> String,
                       file: StaticString,
                       line: Int,
                       function: StaticString)
}

extension Logger {
    /// The public API for `Logger`. Calls
    /// `writeLogEntry(_:,_:,file:,line:,function:)`.
    func log(
        _ logLevel: LogLevel,
        _ message: @autoclosure () -> String,
                       file: StaticString = #file,
                       line: Int = #line,
                       function: StaticString = #function)
    {
        writeLogEntry(logLevel, message,
                      file: file, line: line,
                      function: function)
    }
}

struct PrintLogger {
    let minimumLogLevel: LogLevel
}

extension PrintLogger: Logger {
    func writeLogEntry(
        _ logLevel: LogLevel,
        _ message: @autoclosure () -> String,
                       file: StaticString,
                       line: Int,
                       function: StaticString)
    {
        if logLevel >= minimumLogLevel {
            // print("\(logLevel) – \(file):\(line) – \(function) – \(message())")
            var printStr = ""
            if logLevel == .minimal {
                printStr = message()
            } else {
                let fileURL = URL(fileURLWithPath: String(describing: file))
                let trimmedURL = fileURL.deletingPathExtension()
                let filename = trimmedURL.lastPathComponent
                printStr = "\(filename).\(function) - \(logLevel)"
                let str: String = message()
                if str == "" {
                    printStr = "\n" + printStr // if message is blank - prefix with newline
                } else {
                    printStr = printStr + "\n\t\(str)" // add details (don't print line number)
                }
            }
            DispatchQueue.main.async { () -> Void in
                print(printStr) // don't print line number
            }
        }
    }
}









