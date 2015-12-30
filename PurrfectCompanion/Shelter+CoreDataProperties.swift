//
//  Shelter+CoreDataProperties.swift
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

extension Shelter {

    @NSManaged var name: String?
    @NSManaged var id: String?
    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var location: String?
    @NSManaged var address: String?
    @NSManaged var zipCode: String?
    @NSManaged var email: String?
    @NSManaged var telephone: String?
    @NSManaged var website: String?
    
    // Relationships
    @NSManaged var cats: NSSet?
    @NSManaged var pin: Pin?

}
