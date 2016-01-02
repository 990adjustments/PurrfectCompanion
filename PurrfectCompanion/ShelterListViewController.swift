//
//  ShelterListViewController.swift
//  PurrfectCompanion
//
//  Created by Erwin Santacruz on 11/23/15.
//  Copyright © 2015 Erwin Santacruz. All rights reserved.
//

import UIKit
import CoreData
import MapKit

private let REUSE_IDENTIFIER = "Cell"

class ShelterListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate, CLLocationManagerDelegate, NSFetchedResultsControllerDelegate {
    
    var mapCoordinates: CLLocationCoordinate2D!
    var refreshButton: UIBarButtonItem!
    var lat: String?
    var long: String?
    
    // Will implement this in the future
    //var editButton: UIBarButtonItem!
    //var trashButton: UIBarButtonItem!
    //var flexSpaceButton: UIBarButtonItem!
    
    var shelterList: [Shelter]!
    var client: Client!
    var pin: Pin!
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    var selectedIndexes = [NSIndexPath]()
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStack.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Shelter")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    @IBOutlet weak var searcbar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            self.mapView.mapType = .Standard
            self.mapView.delegate = self
        }
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        client = Client.sharedInstance()
        
        shelterList = Utilities.fetchObjects(fetchedResultsController) as! [Shelter]
        
        // Begin long process to grab pet information
        var temporaryContext: NSManagedObjectContext!
        temporaryContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        temporaryContext.persistentStoreCoordinator = self.sharedContext.persistentStoreCoordinator
        
        sharedContext.performBlock({ () -> Void in
            for shelterItem in self.shelterList {
                if shelterItem.cats?.count == 0 {
                
                    self.client.getPetInfo(shelterItem, ShelterID: shelterItem.id!, completion: { (errorstring) -> () in
                        if let err = errorstring {
                            print(err)
                            return
                        }
                    })
                }
            }
        })
        
        setupUI()
        setupMap()
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)

        navigationItem.title = pin.title
        
        tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        searchBarCancelButtonClicked(searcbar)
    }
    
    func setupUI()
    {
        // Navigation buttons
        refreshButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: Selector("refreshCollection"))
        
        navigationItem.setRightBarButtonItems([refreshButton], animated: true)
        navigationItem.title = pin.title
    }
    
    func setupMap()
    {
        if let pinObject = pin {
            mapCoordinates = CLLocationCoordinate2D(latitude: pinObject.latitude as! Double, longitude: pinObject.longitude as! Double)
            
            let span = MKCoordinateSpan(latitudeDelta: 2.5, longitudeDelta: 2.5)
            let region = MKCoordinateRegionMake(mapCoordinates, span)
            
            mapView.setRegion(region, animated: true)
            mapView.centerCoordinate = mapCoordinates
            
            mapView.addAnnotation(pin as MKAnnotation)
        }
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        if let sectionInfo = fetchedResultsController.sections {
            return sectionInfo.count
        }
        
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier(REUSE_IDENTIFIER, forIndexPath: indexPath) as! ShelterListViewCell

        // Configure the cell...
        let shelterInfo = fetchedResultsController.objectAtIndexPath(indexPath) as! Shelter
        
        cell.nameLabel.text = shelterInfo.name
        cell.addressLabel.text = shelterInfo.address
        cell.zipCodeLabel.text = shelterInfo.zipCode
        cell.cityStateLabel.text = shelterInfo.location
        cell.emailLabel.text = shelterInfo.email
        cell.telephoneLabel.text = shelterInfo.telephone

        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        pushCollectionViewController(indexPath)
    }
    
    func pushCollectionViewController(indexpath: NSIndexPath!)
    {
        let connection = Utilities.isConnectedToNetwork()
        if !connection {
            presentAlert("There has been a connection error. The Internet connection appears to be offline.", completionHandler: { (bool) -> () in
                if bool {
                    print("Try again")
                    self.pushCollectionViewController(indexpath)
                }
                else {
                    print("Bail out")
                    self.tableView.deselectRowAtIndexPath(indexpath, animated: true)
                    return
                }
            })
        }
        else {
            performSegueWithIdentifier("shelterSegueID", sender: self)
        }
    }
    
    func presentAlert(error: String?, completionHandler:(Bool) -> ())
    {
        let alertController = UIAlertController(title: "Connection Error", message: error, preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) -> Void in
            completionHandler(false)
        }
        
        let retryAction = UIAlertAction(title: "Retry", style: .Default) { (action) -> Void in
            completionHandler(true)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(retryAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func refreshCollection()
    {
        let connection = Utilities.isConnectedToNetwork()
        
        if !connection {
            presentAlert("There has been a connection error. The Internet connection appears to be offline.", completionHandler: { (bool) -> () in
                if bool {
                    print("Try refetch")
                    self.refreshCollection()
                }
                else {
                    print("Bail out")
                    return
                }
            })
        }
        else {
            tableView.alpha = 0.5
            retrievePetInformation()
        }
    }
    
    func retrievePetInformation()
    {
        let fetchedShelters = fetchedResultsController.fetchedObjects as! [Shelter]
        
        for i in fetchedShelters {
            sharedContext.deleteObject(i)
        }
        
        client.getShelterInfo(pin) { (errorstring) -> () in
            if let err = errorstring {
                print("Error retrieving shelter information: \(err)")
            }
            
            self.shelterList = Utilities.fetchObjects(self.fetchedResultsController) as! [Shelter]
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
                self.tableView.alpha = 1.0
            })
            
            self.sharedContext.performBlock({ () -> Void in
                for shelterItem in self.shelterList {
                    if shelterItem.cats?.count == 0 {
                        
                        self.client.getPetInfo(shelterItem, ShelterID: shelterItem.id!, completion: { (errorstring) -> () in
                            if let err = errorstring {
                                print("Error retrieving pet information: \(err)")
                            }
                        })
                    }
                }
            })
        }
    }
    
    // MARK: - Search
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String)
    {
        searchBar.setShowsCancelButton(true, animated: true)
        
        if !searchText.isEmpty {
            // Setup the fetch request
            let fetchRequest = NSFetchRequest(entityName: "Shelter")
            
            fetchRequest.fetchLimit = 25
            
            //set OR predicate to search for shelter by name or location
            let namePredicate = NSPredicate(format: "name contains[c] %@", searchText)
            let locationPredicate = NSPredicate(format: "location contains[c] %@", searchText)
            let zipcodePredicate = NSPredicate(format: "zipCode contains[c] %@", searchText)
            let compoundOrPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [namePredicate, locationPredicate, zipcodePredicate])
            
            //fetchRequest.predicate = NSPredicate(format: "name contains[c] %@", searchText)
            fetchRequest.predicate = compoundOrPredicate
            
            let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            // Pass the fetchRequest and the context as parameters to the fetchedResultController
            fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext:sharedContext,
                sectionNameKeyPath: nil, cacheName: nil)
            
            fetchedResultsController.delegate = self
            
            shelterList = Utilities.fetchObjects(fetchedResultsController) as! [Shelter]
            tableView.reloadData()
        }
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar!) {
        searchBar.text = nil
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        
        // Bring back original data
        let fetchRequest = NSFetchRequest(entityName: "Shelter")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        shelterList = Utilities.fetchObjects(fetchedResultsController) as! [Shelter]
        
        tableView.reloadData()
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "shelterSegueID" {
            let vc = segue.destinationViewController as! ShelterViewController
            let row = tableView.indexPathForSelectedRow?.row
            
            shelterList = Utilities.fetchObjects(fetchedResultsController) as! [Shelter]
            
            let shelterItem = shelterList[row!]
            
            vc.shelter = shelterItem
        }
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
