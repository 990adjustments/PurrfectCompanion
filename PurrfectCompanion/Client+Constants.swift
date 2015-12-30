//
//  Client+Constants.swift
//  PurrfectCompanion
//
//  Created by Erwin Santacruz on 11/18/15.
//  Copyright © 2015 Erwin Santacruz. All rights reserved.
//

extension Client {
    
    // Shelter methods
    struct methods  {
        static let BASE_URL = "https://api.petfinder.com/"
        static let SHELTER_FIND = "shelter.find"
        static let SHELTER_GET = "shelter.get"
        static let SHELTER_LIST_BY_BREED = "shelter.listByBreed"
        static let SHELTER_GET_PETS = "shelter.getPets"
        static let BREED_LIST = "breed.list"
        static let PET_GET = "pet.get"
        static let PET_FIND = "pet.find"
        static let PET_GET_RANDOM = "pet.getRandom"
    }
    
    // Shelter parameters
    struct parameters {
        static let API_KEY = "99c2c6fde00fb9cff7f89a0fa738dde2"
        static let FORMAT = "json"
        static let ANIMAL = "cat"
        static let OUTPUT = "full"
        
        /*
        //These are variables for retrieving a specific shelter
        LOCATION
        NAME
        OFFSET
        ID
        */
    }
}
