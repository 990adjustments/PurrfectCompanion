//
//  Photo.swift
//  PurrfectCompanion
//
//  Created by Erwin Santacruz on 11/18/15.
//  Copyright © 2015 Erwin Santacruz. All rights reserved.
//

import Foundation
import CoreData


class Photo: NSManagedObject {
    
    var dataDir: NSURL?

    func savePathUrl(photoid: String!, imgUrl: String!, shelterid: String!) -> NSURL?
    {
        dataDir = Utilities.fileOperations.CACHE_DIR
        
        // Check for data directory
        if !Utilities.fileOperations.FILE_MANAGER.fileExistsAtPath((dataDir?.path)!) {
            print("Create subdirectory")
            do {
                try Utilities.fileOperations.FILE_MANAGER.createDirectoryAtURL(dataDir!, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                print("Error creating directory")
            }
        }
        
        let nsurl = NSURL(string: imgUrl!)
        
        let data = NSData(contentsOfURL: nsurl!)
        
        guard let imageData = data else {
            print("Image data incomplete")
            return nil
        }
        
        // Create subdirectory for shelter images
        let shelterDir = dataDir?.URLByAppendingPathComponent(shelterid, isDirectory: true)
        
        if !Utilities.fileOperations.FILE_MANAGER.fileExistsAtPath((shelterDir?.path)!) {
            print("Create shelter subdirectory")
            do {
                try Utilities.fileOperations.FILE_MANAGER.createDirectoryAtURL(shelterDir!, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                print("Error creating shelter directory")
            }
        }
        
        let path = shelterDir?.URLByAppendingPathComponent(photoid)
        
        guard let _ = path else {
            print("Invalid path")
            return nil
        }
        
        imageData.writeToURL(path!, atomically: true)
        
        return path
    }
    
    override func prepareForDeletion()
    {
        let _ = Utilities.imageCleanup(id!, shelterid: shelterId!)
    }

}
