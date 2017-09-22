//
//  Extensions.swift
//  ArmorVox
//
//  Created by Rob Dixon on 07/08/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import UIKit

// MARK: - UITableView

extension UITableView {
    // appendRows
    func appendRows(numRows: Int, inSection section: Int, with animation: UITableViewRowAnimation) {
        let existingRowCount = self.numberOfRows(inSection: section)
        var indexPaths: [IndexPath] = []
        for newRow in existingRowCount..<(existingRowCount + numRows) {
            let indexPath = IndexPath(row: newRow, section: section)
            indexPaths.append(indexPath)
        }
        self.insertRows(at: indexPaths, with: animation)
    }
    
    // deleteRows
    func deleteRows(rows: [Int], fromSection section: Int, with animation: UITableViewRowAnimation) {
        var indexPaths: [IndexPath] = []
        for row in rows {
            let indexPath = IndexPath(row: row, section: section)
            indexPaths.append(indexPath)
        }
        self.deleteRows(at: indexPaths, with: animation)
    }
    
    // deleteAllRows (in Section)
    func deleteAllRows(inSection section: Int, with animation: UITableViewRowAnimation) {
        var iPaths: [IndexPath] = []
        for row in 0..<self.numberOfRows(inSection: section) {
            let iPath = IndexPath(row: row, section: section)
            iPaths.append(iPath)
        }
        self.deleteRows(at: iPaths, with: animation)
    }
}



// MARK: - IndexPath

extension IndexPath {
    
    func isSectionLastRow(inTableView tableView: UITableView) -> Bool {
        // is self the last row in it's section of tableView
        return row == tableView.numberOfRows(inSection: section) - 1
    }
}



// MARK: - UIColor

extension UIColor {
    static let backgroundWhenRecording = UIColor(red: 255.0/255, green: 165.0/255, blue: 155.0/255, alpha: 1.0)
    static let backgroundWhenNotRecording = UIColor.white
}
