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
    var lat: String?
    var long: String?
    
    //var editButton: UIBarButtonItem!
    var refreshButton: UIBarButtonItem!
    var trashButton: UIBarButtonItem!
    var flexSpaceButton: UIBarButtonItem!
    
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
        
        //*********************************************************************************
        //*********************************************************************************
        
        // Tryig to retrieve data in background but UI still seems to lock up
        
        //*********************************************************************************
        //*********************************************************************************
        
        // Begin long process
        /*
        var temporaryContext: NSManagedObjectContext!
        temporaryContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        temporaryContext.persistentStoreCoordinator = self.sharedContext.persistentStoreCoordinator
        
        temporaryContext.performBlock({ () -> Void in
            for shelterItem in self.shelterList {
                
                self.client.getPetInfo(shelterItem, ShelterID: shelterItem.id!, completion: { (errorstring) -> () in
                    if let err = errorstring {
                        print(err)
                        return
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.tableView.reloadData()
                    })
                })
            }
        })
        */

        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) { () -> Void in
            for shelterItem in self.shelterList {
                if shelterItem.cats?.count == 0 {
                
                    self.client.getPetInfo(shelterItem, ShelterID: shelterItem.id!, completion: { (errorstring) -> () in
                        if let err = errorstring {
                            print(err)
                            return
                        }
                        
    //                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
    //                        self.tableView.reloadData()
    //                    })
                    })
                }
            }
        }
        
        setupUI()
        setupMap()
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)

        navigationItem.title = pin.title
        
        tableView.reloadData()
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
