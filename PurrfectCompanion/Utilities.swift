//
//  Utilities.swift
//  PurrfectCompanion
//
//  Created by Erwin Santacruz on 11/13/15.
//  Copyright © 2015 Erwin Santacruz. All rights reserved.
//

import UIKit
import CoreData
import SystemConfiguration

class Utilities: NSObject, NSFetchedResultsControllerDelegate {
    
    class func imageCleanup(id: String!, shelterid: String!) -> (Bool, String?)
    {
        //let imagePath = Utilities.fileOperations.CACHE_DIR.URLByAppendingPathComponent(id)
        let imagePath = Utilities.fileOperations.CACHE_DIR.URLByAppendingPathComponent(shelterid+"/"+id)
        
        if Utilities.fileOperations.FILE_MANAGER.fileExistsAtPath(imagePath.path!) {
            if let _ = Utilities.fileOperations.FILE_MANAGER.contentsAtPath(imagePath.path!) {
                
                do {
                    try Utilities.fileOperations.FILE_MANAGER.removeItemAtURL(imagePath)
                    
                    return (true, nil)
                }
                catch {
                    print("Unable to delete data.")
                    let errorString = "Opps! The file does not exist"
                    return (false, errorString)
                    
                }
            }
            else {
                return (false, "No data found.")
            }
        }
        
        return (false, "File does not exist.")
    }
    
    class func removeDirectory(shelterid: String?)
    {
        let imagePath = Utilities.fileOperations.CACHE_DIR.URLByAppendingPathComponent(shelterid!)

        if Utilities.fileOperations.FILE_MANAGER.fileExistsAtPath(imagePath.path!) {
            do {
                let contents = try Utilities.fileOperations.FILE_MANAGER.contentsOfDirectoryAtPath(imagePath.path!)
                    if contents.isEmpty {
                        print("Removing directory: \(imagePath)")
                        
                        do {
                            try Utilities.fileOperations.FILE_MANAGER.removeItemAtURL(imagePath)
                        }
                        catch {
                            print("Unable to delete directory at: \(imagePath).")
                        }
                        
                    }
            }
            catch {
                print("Unable to delete directory at: \(imagePath).")
            }
        }
        else {
            print("Directory does not exist at: \(imagePath).")
        }
    }
    
    class func fetchObjects(fetchedResultsController: NSFetchedResultsController) -> [AnyObject]!
    {
        // Start the fetched results controller
        let sheltersArray:[AnyObject]!
        
        do {
            try fetchedResultsController.performFetch()
            
            if let fetchedShelters = fetchedResultsController.fetchedObjects {
                sheltersArray = fetchedShelters
            }
            else {
                print("No fetchedResultsController.fetchedObjects found.")
                sheltersArray = nil
            }
        }
        catch {
            print("No results found.")
            sheltersArray = nil
        }
        
        return sheltersArray
    }

    class func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }

}
