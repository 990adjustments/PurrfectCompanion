//
//  Pin+CoreDataProperties.swift
//  PurrfectCompanion
//
//  Created by Erwin Santacruz on 12/21/15.
//  Copyright © 2015 Erwin Santacruz. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Pin {

    @NSManaged var longitude: NSNumber?
    @NSManaged var latitude: NSNumber?
    @NSManaged var zipCode: String?
    @NSManaged var title: String?
    @NSManaged var id: String?
    
    // Relationships
    @NSManaged var shelters: NSSet?

}
