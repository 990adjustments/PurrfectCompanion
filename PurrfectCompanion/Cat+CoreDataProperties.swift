//
//  Cat+CoreDataProperties.swift
//  PurrfectCompanion
//
//  Created by Erwin Santacruz on 11/18/15.
//  Copyright © 2015 Erwin Santacruz. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Cat {

    @NSManaged var age: String?
    @NSManaged var sex: String?
    @NSManaged var id: String?
    @NSManaged var name: String?
    
    // Relationships
    @NSManaged var photos: NSSet?
    @NSManaged var shelter: Shelter?

}
