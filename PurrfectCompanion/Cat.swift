//
//  Cat.swift
//  PurrfectCompanion
//
//  Created by Erwin Santacruz on 11/18/15.
//  Copyright © 2015 Erwin Santacruz. All rights reserved.
//

import Foundation
import CoreData


class Cat: NSManagedObject {

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary:[String : AnyObject?], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Cat", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        name = dictionary["name"] as? String
        id = dictionary["id"] as? String
        sex = dictionary["sex"] as? String
        age = dictionary["age"] as? String
    }
}
