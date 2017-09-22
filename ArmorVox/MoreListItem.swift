//
//  MoreListItem.swift
//  ArmorVox
//
//  Created by Rob Dixon on 27/07/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import UIKit

class MoreListitem {
    
    let image: UIImage?
    let text: String
    let segueID: String
    
    init(image: UIImage?, text: String, segueID: String) {
        self.image = image
        self.text = text
        self.segueID = segueID
    }
}
