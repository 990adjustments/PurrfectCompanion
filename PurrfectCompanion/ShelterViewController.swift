//
//  ShelterViewController.swift
//  PurrfectCompanion
//
//  Created by Erwin Santacruz on 11/23/15.
//  Copyright © 2015 Erwin Santacruz. All rights reserved.
//

import UIKit
import CoreData
import MapKit

private let reuseIdentifier = "CollectionViewCell"

class ShelterViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDelegate {

    var shelter: Shelter!
    var catList: [Cat]!
    var client: Client!
    
    // UI objects
    var editButton: UIBarButtonItem!
    var refreshButton: UIBarButtonItem!
    var trashButton: UIBarButtonItem!
    var flexSpaceButton: UIBarButtonItem!
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    var selectedIndexes = [NSIndexPath]()
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStack.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Cat")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "age", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "shelter == %@", self.shelter);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.delegate = self
        }
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        client = Client.sharedInstance()

        catList = Utilities.fetchObjects(fetchedResultsController) as! [Cat]
        
        setupUI()
    }
    
    override func viewWillAppear(animated: Bool)
    {
        navigationItem.title = shelter.name
        
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        // Check if user remained in edit mode
        if !navigationController!.toolbarHidden {
            navigationController?.setToolbarHidden(true, animated: true)
        }
    }
    
    func setupUI()
    {
        // Navigation buttons
        editButton = editButtonItem()
        refreshButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: Selector("refreshCollection"))
        
        navigationItem.setRightBarButtonItems([editButton, refreshButton], animated: true)
        navigationItem.title = shelter.name
        
        // Remove text from back button
        navigationController?.navigationBar.topItem!.title = ""
        
        // Toolbar buttons
        trashButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: Selector("deleteImages"))
        
        flexSpaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        
        self.setToolbarItems([flexSpaceButton, trashButton], animated: true)
        navigationController!.setToolbarHidden(true, animated: true)
    }
    
    override func setEditing(editing: Bool, animated: Bool)
    {
        super.setEditing(editing, animated: animated)
        
        if editing {
            navigationItem.title = "Select images"
            navigationController?.setToolbarHidden(false, animated: true)
            collectionView.allowsMultipleSelection = true
        }
        else {
            navigationItem.title = shelter.name
            navigationController?.setToolbarHidden(true, animated: true)
            
            for indexPath in selectedIndexes {
                let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ShelterViewCell
                cell.photoCell.alpha = 1.0
                collectionView.deselectItemAtIndexPath(indexPath, animated: true)
            }
            
            selectedIndexes.removeAll()
        }
    }
    
    func configureCell(cell: ShelterViewCell, indexPath:NSIndexPath)
    {
        let cat = fetchedResultsController.objectAtIndexPath(indexPath) as? Cat
        
        cell.activityIndicator.startAnimating()
        
        let id = cat?.id!
        //let imagePath = Utilities.fileOperations.CACHE_DIR.URLByAppendingPathComponent(id!)
        let imagePath = Utilities.fileOperations.CACHE_DIR.URLByAppendingPathComponent(shelter.id!+"/"+id!)
        
        if let imageData = Utilities.fileOperations.FILE_MANAGER.contentsAtPath(imagePath.path!) {
            //print("DISK DATA")
            let img = UIImage(data: imageData)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                cell.photoCell.image = img
                cell.activityIndicator.stopAnimating()
            })
        }
        else {
            // File is not on disk, so download from network
            // First create a background context for long operation
            //print("NETWORK DATA")
            let shelterid = shelter.id!
            
            var temporaryContext: NSManagedObjectContext!
            temporaryContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
            temporaryContext.persistentStoreCoordinator = self.sharedContext.persistentStoreCoordinator
            
            temporaryContext.performBlock({ () -> Void in
                //print("THREAD ONE: \(NSThread.isMainThread())")
                var mo: Cat!
                
                do {
                    mo = try temporaryContext.existingObjectWithID((cat?.objectID)!) as! Cat
                }
                catch {
                    print(error)
                }
                
                //let photoSet = mo.valueForKey("photos") as! Set<Photo>
                let photoSet = mo.photos as! Set<Photo>
                
                // I will eventually deal with multiple photosets
                // For now I will use the first image
                let photo = photoSet.first!
                let id = photo.id
                
                if let imageUrlString = photo.imgUrl {
                    if let imageUrl = NSURL(string: imageUrlString) {
                        if let imageData = NSData(contentsOfURL: imageUrl) {
                            // Save data to disk
                            //print("THREAD TWO: \(NSThread.isMainThread())")
                            photo.savePathUrl(id!, imgUrl: imageUrlString, shelterid: shelterid)

                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                //print("THREAD FOUR: \(NSThread.isMainThread())")
                                cell.photoCell.image = UIImage(data: imageData)
                                cell.activityIndicator.stopAnimating()
                            })
                        }
                    }
                }
           })
        }
    }
    
    func deleteImages()
    {
        /*
        // Used for debugging
        let fetchRequest = NSFetchRequest(entityName: "Cat")
        fetchRequest.predicate = NSPredicate(format: "shelter == %@", self.shelter)
        
        do {
            let results = try sharedContext.executeFetchRequest(fetchRequest)
            print(results?.first)
        }
        catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        */
        
        if selectedIndexes.isEmpty {
            return
        }
        else {
            deleteAlert(nil, completionHandler: { (bool) -> () in
                if bool {
                    self.deleteImagesAtIndexPath()
                }
            })
        }
    }
    
    func deleteImagesAtIndexPath()
    {
        var catsToDelete = [Cat]()
        
        for indexPath in selectedIndexes {
            catsToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Cat)
        }
        
        for i in catsToDelete {
            sharedContext.deleteObject(i)
            
            CoreDataStack.sharedInstance().saveContext()
        }
        
        selectedIndexes = [NSIndexPath]()
        
        navigationItem.title = "Select images"
    }

    
    func deleteAlert(error:String?, completionHandler:(Bool) -> ())
    {
        let alertController = UIAlertController(title: nil, message: error, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive) { (action) in
            completionHandler(true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) in
            completionHandler(false)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "petSegueID" {
            let vc = segue.destinationViewController as! PetViewController
            let index = collectionView.indexPathsForSelectedItems()?.first!
            catList = Utilities.fetchObjects(fetchedResultsController) as! [Cat]
            
            //let catItem = catList[(index?.item)!]
            let catItem = catList[(index?.row)!]
            vc.cat = catItem
        }
    }

    // MARK: - UICollectionViewDataSource

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int
    {
        return fetchedResultsController.sections?.count ?? 0
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        let sectionInfo = fetchedResultsController.sections![section]
        
        if sectionInfo.numberOfObjects == 0 {
            let img = UIImageView(image: UIImage(named: "no-pictures"))
            img.contentMode = UIViewContentMode.ScaleAspectFill
            collectionView.backgroundView = img
        }
        else {
            let colorview = UIView()
            colorview.backgroundColor = NAV_COLOR
            collectionView.backgroundView = colorview
        }
        
        //print("Number of cells: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! ShelterViewCell
    
        // Configure the cell
        cell.photoCell.alpha = selectedIndexes.contains(indexPath) ? 0.2 : 1.0
        configureCell(cell, indexPath: indexPath)
    
        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ShelterViewCell
        
        if editing {
            //print(cell.highlighted)
            let containsIndexPath = selectedIndexes.contains(indexPath)
            
            if !containsIndexPath {
                cell.photoCell.alpha = 0.2
                selectedIndexes.append(indexPath)
            }
            
            let imgCount = selectedIndexes.count > 1 ? "images selected" : "image selected"
            let stringTitle = selectedIndexes.count == 0 ? "Select images" : "\(selectedIndexes.count) \(imgCount)"
            navigationItem.title = "\(stringTitle)"
        }
        else {
            //collectionView.deselectItemAtIndexPath(indexPath, animated: true)
            performSegueWithIdentifier("petSegueID", sender: indexPath)
        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath)
    {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ShelterViewCell
        
        if editing {
            if selectedIndexes.contains(indexPath) {
            let index = selectedIndexes.indexOf(indexPath)
            
            cell.photoCell.alpha = 1.0
            selectedIndexes.removeAtIndex(index!)
            }
            
            let imgCount = selectedIndexes.count > 1 ? "images selected" : "image selected"
            let stringTitle = selectedIndexes.count == 0 ? "Select images" : "\(selectedIndexes.count) \(imgCount)"
            navigationItem.title = "\(stringTitle)"
        }
            else {
            collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        }
    }

    // MARK: - Fetched Results Controller Delegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController)
    {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
    {
        switch type {
            
            case .Insert:
                //print("Insert an item")
                insertedIndexPaths.append(newIndexPath!)
                break
            case .Delete:
                //print("Delete an item")
                deletedIndexPaths.append(indexPath!)
                break
            case .Update:
                //print("Update an item.")
                updatedIndexPaths.append(indexPath!)
                break
            default:
                break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
        //print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil )
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
        
        let pet = fetchedResultsController.fetchedObjects as! [Cat]
        
        for i in pet {
            //let _ = Utilities.imageCleanup(i.id!)
            sharedContext.deleteObject(i)
        }
        
        self.client.getPetInfo(shelter, ShelterID: shelter.id!, completion: { (errorstring) -> () in
            //print(NSThread.isMainThread())
            
            self.catList = Utilities.fetchObjects(self.fetchedResultsController) as! [Cat]
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.collectionView.reloadData()
            })
        })
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
