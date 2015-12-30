//
//  Shelter.swift
//  PurrfectCompanion
//
//  Created by Erwin Santacruz on 11/18/15.
//  Copyright © 2015 Erwin Santacruz. All rights reserved.
//

import Foundation
import CoreData
import MapKit


class Shelter: NSManagedObject {
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary:[String : AnyObject?], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Shelter", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        name = dictionary["name"] as? String
        id = dictionary["id"] as? String
        latitude = dictionary["latitude"] as! Double
        longitude = dictionary["longitude"] as! Double
        location = dictionary["location"] as? String
        address = dictionary["address"] as? String
        zipCode = dictionary["zipCode"] as? String
        email = dictionary["email"] as? String
        telephone = dictionary["telephone"] as? String
        
        // Future implementation. No API support
        //website = dictionary["website"] as? String
    }
}
