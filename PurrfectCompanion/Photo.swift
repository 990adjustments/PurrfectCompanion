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

    func savePathUrl(photoid: String!, shelterid: String!) -> NSURL?
    {
        dataDir = Utilities.fileOperations.CACHE_DIR
        //print(dataDir)
        
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
        //let path = dataDir?.URLByAppendingPathComponent(photoid)
        
        let shelterDir = dataDir?.URLByAppendingPathComponent(shelterid, isDirectory: true)
        //print(shelterDir!)
        
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
        //print(path!)
        
        data!.writeToURL(path!, atomically: true)
        
        return path
    }
    
    override func prepareForDeletion()
    {
        //let _ = Utilities.imageCleanup(id!)
        let _ = Utilities.imageCleanup(id!, shelterid: shelterId!)
    }

}
