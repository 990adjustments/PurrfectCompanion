//
//  Photo+CoreDataProperties.swift
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

extension Photo {

    @NSManaged var id: String?
    @NSManaged var imgUrl: String?
    @NSManaged var shelterId: String?
    
    // Relationships
    @NSManaged var cat: Cat?

}
