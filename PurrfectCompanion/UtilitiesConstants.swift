//
//  UtilitiesConstants.swift
//  PurrfectCompanion
//
//  Created by Erwin Santacruz on 11/13/15.
//  Copyright © 2015 Erwin Santacruz. All rights reserved.
//

import UIKit

let NAV_COLOR = UIColor(red: 251.0/255, green: 130.0/255, blue: 10.0/255, alpha: 1.0)

extension Utilities {
    struct fileOperations {
        static let CACHE_IDENTIFIER = "Images"
        static let FILE_MANAGER = NSFileManager.defaultManager()
        static let CACHE_DIR = FILE_MANAGER.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!.URLByAppendingPathComponent(CACHE_IDENTIFIER, isDirectory: true)
    }
}