//
//  Client.swift
//  PurrfectCompanion
//
//  Created by Erwin Santacruz on 11/13/15.
//  Copyright © 2015 Erwin Santacruz. All rights reserved.
//

import Foundation
import CoreData


class Client: NSObject, NSFetchedResultsControllerDelegate {
    
    var session: NSURLSession
    var sharedContext: NSManagedObjectContext
    
    override init() {
        session = NSURLSession.sharedSession()
        sharedContext = CoreDataStack.sharedInstance().managedObjectContext
        
        super.init()
    }
    
    class func sharedInstance() -> Client {
        struct Static {
            static let instance = Client()
        }
        
        return Static.instance
    }
    
    func getShelterInfo(pin: Pin, completion:(errorstring: String?) ->())
    {
        let urlString = "\(Client.methods.BASE_URL)\(Client.methods.SHELTER_FIND)?key=\(Client.parameters.API_KEY)&location=\(pin.zipCode!)&format=\(Client.parameters.FORMAT)"

        let escapedURLString = urlString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        
        initiateRequest(escapedURLString!, completionHandler: { (results, error) -> () in
            if let err = error {
                print(err.localizedDescription)
                completion(errorstring: err.localizedDescription)
            }
            
            let error: String = "Unable to retrieve data."
            if let jsonData = results {
                if let dataDictionary = jsonData.valueForKey("petfinder") as? NSDictionary {
                    if let sheltersDictionary = dataDictionary.valueForKey("shelters") as? NSDictionary {
                        if let shelterArray = sheltersDictionary.valueForKey("shelter") as? [[String:AnyObject]] {
                            
                            self.sharedContext.performBlock({ () -> Void in
                                //print(NSThread.isMainThread())
                                
                                for shelterItem in shelterArray {
                                    let shelterLocation = "\(shelterItem["city"]!["$t"] as! String), \(shelterItem["state"]!["$t"] as! String)"
                                    
                                    let lat = shelterItem["latitude"]!["$t"] as? String
                                    let lon = shelterItem["longitude"]!["$t"] as? String
                                    
                                    let dict: [String:AnyObject?] = [
                                        "name" : shelterItem["name"]!["$t"] as? String,
                                        "id" : shelterItem["id"]!["$t"] as? String,
                                        "latitude" : Double(lat!),
                                        "longitude" : Double(lon!),
                                        "location" : shelterLocation,
                                        "address" : shelterItem["address1"]!["$t"] as? String,
                                        "zipCode" : shelterItem["zip"]!["$t"] as? String,
                                        "email" : shelterItem["email"]!["$t"] as? String,
                                        "telephone" : shelterItem["phone"]!["$t"] as? String,
                                        //"website" : i["website"]!["$t"] as? String,
                                    ]
                                    
                                    // Create Shelter object
                                    let shelter = Shelter(dictionary: dict, context: self.sharedContext)
                                    shelter.pin = pin
                                    
                                    pin.id = shelter.id
                                }
                                
                                CoreDataStack.sharedInstance().saveContext()
                            })
                            
                            completion(errorstring: nil)
                        }
                        else {
                           completion(errorstring: error)
                        }
                    }
                    else {
                        completion(errorstring: error)
                    }
                }
                else {
                    completion(errorstring: error)
                }
            }
            else {
                completion(errorstring: error)
            }
        })
    }
    
    func getPetInfo(shelter: Shelter, ShelterID: String, completion:(errorstring: String?) ->())
    {
        let urlString = "\(Client.methods.BASE_URL)\(Client.methods.SHELTER_GET_PETS)?key=\(Client.parameters.API_KEY)&format=\(Client.parameters.FORMAT)&id=\(ShelterID)"

        let escapedURLString = urlString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        
        initiateRequest(escapedURLString!, completionHandler: { (results, error) -> () in
            if let err = error {
                print(err.localizedDescription)
                completion(errorstring: err.localizedDescription)
            }
            
            let error: String = "Unable to retrieve data."
            if let jsonData = results {
                if let dataDictionary = jsonData.valueForKey("petfinder") as? NSDictionary {
                    if let petsDictionary = dataDictionary.valueForKey("pets") as? NSDictionary {
                        if let petArray = petsDictionary.valueForKey("pet") as? [[String:AnyObject]] {
                            
                            self.sharedContext.performBlock({ () -> Void in
                                //print(NSThread.isMainThread())
                                
                                for pet in petArray {
                                    if pet["animal"]!["$t"] as! String == "Cat" ||  pet["animal"]!["$t"] as! String == "Dog"{
                                        
                                        let dict: [String:AnyObject?] = [
                                            "name" : pet["name"]!["$t"] as? String,
                                            "id" : pet["id"]!["$t"] as? String,
                                            "age" : pet["age"]!["$t"] as? String,
                                            "sex" : pet["sex"]!["$t"] as? String,
                                        ]

                                        if let photosDictionary = pet["media"]?.valueForKey("photos") as? NSDictionary {
                                            if let photoArray = photosDictionary.valueForKey("photo") as? [[String:AnyObject]] {
                                                for pic in photoArray {
                                                    if pic["@size"]! as! String == "x" && pic["@id"]! as! String == "1"{
                                                        let imgUrl = pic["$t"]! as! String
                                                        
                                                        // Create Cat object
                                                        let cat = Cat(dictionary: dict, context: self.sharedContext)
                                                        cat.shelter = shelter
                                                        
                                                        // Create Photo object
                                                        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: self.sharedContext)
                                                        let photo = Photo(entity:entity!, insertIntoManagedObjectContext: self.sharedContext)
                                                        
                                                        photo.imgUrl = imgUrl
                                                        photo.id = cat.id
                                                        photo.cat = cat
                                                        photo.shelterId = ShelterID
                                                    }
                                                }
                                            }
                                            
                                            CoreDataStack.sharedInstance().saveContext()
                                        }
                                    }
                                    else {
                                        print("Sorry, we only do dogs or cats.")
                                    }
                                }
                            })
                            
                            completion(errorstring: nil)
                        }
                        else {
                            completion(errorstring: error)
                        }
                    }
                    else {
                        completion(errorstring: error)
                    }
                }
                else {
                    completion(errorstring: error)
                }
            }
            else {
                completion(errorstring: error)
            }
        })
    }
    
    func clientRequest(object: AnyObject, urlString: String, completion:(jsonData: AnyObject?, errorstring: String?) -> ())
    {
        let escapedURLString = urlString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        
        initiateRequest(escapedURLString!, completionHandler: { (results, error) -> () in
            if let err = error {
                print(err.localizedDescription)
                completion(jsonData: nil, errorstring: err.localizedDescription)
            }
            
            if let jsonData = results {
                print("JSON \(jsonData)")
                completion(jsonData: jsonData, errorstring: nil)
            }
        })
    }
    
    func initiateRequest(resource: String, completionHandler: (results: AnyObject?, error: NSError?) -> ())
    {
        let url = NSURL(string: resource)
        let request = NSURLRequest(URL: url!)
        
        let task = createTask(request, handler: completionHandler)
        task.resume()
    }
    
    func createTask(request: NSURLRequest, handler:(results: AnyObject?, error: NSError?) -> ()) -> NSURLSessionDataTask
    {
        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            if let err = error {
                handler(results: nil, error: err)
            }
            else {
                // parse data
                self.parseJSONData(data!, completionHandler: handler)
            }
        }
        
        return task
    }
    
    func parseJSONData(data: NSData, completionHandler: (result: AnyObject?, error: NSError?) -> ())
    {
        var parseError: NSError?
        
        let parsedResult: AnyObject?
        
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        }
        catch let error as NSError {
            parseError = error
            parsedResult = nil
        }
        
        if let error = parseError {
            completionHandler(result: nil, error: error)
        }
        else {
            completionHandler(result: parsedResult!, error: nil)
        }
        
    }
}