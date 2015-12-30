//
//  MapViewController.swift
//  PurrfectCompanion
//
//  Created by Erwin Santacruz on 11/23/15.
//  Copyright © 2015 Erwin Santacruz. All rights reserved.
//

import UIKit
import CoreData
import MapKit

private let ANNOTATION_IDENTIFIER = "annotationId"

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, NSFetchedResultsControllerDelegate {
    
    var defaults = NSUserDefaults.standardUserDefaults()
    var mapCoordinates: CLLocationCoordinate2D!
    var locationManager: CLLocationManager?
    var pinLocation: String?
    var editButton: UIBarButtonItem!
    
    var client: Client!
    var pin: Pin!

    var sharedContext: NSManagedObjectContext {
        return CoreDataStack.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
    }()
    
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            self.mapView.mapType = .Standard
            self.mapView.delegate = self
            self.mapView.showsUserLocation = false
        }
    }
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! {
        didSet {
            self.activityIndicator.hidesWhenStopped = true
            self.activityIndicator.hidden = true
        }
    }
    
    @IBAction func longPressGesture(sender: UILongPressGestureRecognizer)
    {
        if sender.state == UIGestureRecognizerState.Changed {
            //print("Changed")
            let touchLocation = sender.locationInView(mapView)
            mapCoordinates = mapView.convertPoint(touchLocation, toCoordinateFromView: mapView)
        }
        
        if sender.state == UIGestureRecognizerState.Ended {
            //print("Ended")
            mapView.alpha = 0.5
            
            let touchLocation = sender.locationInView(mapView)
            mapCoordinates = mapView.convertPoint(touchLocation, toCoordinateFromView: mapView)
            
            let loc = CLLocation(latitude: mapCoordinates.latitude, longitude: mapCoordinates.longitude)
            
            activityIndicator.startAnimating()
            dropAnnotation(loc)
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        client = Client.sharedInstance()
        
        fetchedResultsController.delegate = self
        
        setUpMap()
        setUpUI()
        
        if let pinObjects = Utilities.fetchObjects(fetchedResultsController) {
            if !pinObjects.isEmpty {
                // add map annotations
                mapView.addAnnotations(pinObjects as! [MKAnnotation])
                editButton.enabled = true
            }
        }
        else {
            print("No fetchedResultsController.fetchedObjects found.")
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func setUpUI()
    {
        // Setup navigation bar
        navigationController?.navigationBar.barTintColor = NAV_COLOR
        let titleForNav = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 20)!]
        navigationController?.navigationBar.titleTextAttributes = titleForNav
        
        //Setup edit button to delete pins
        editButton = editButtonItem()
        navigationItem.setRightBarButtonItem(editButton, animated: true)
        editButton.enabled = false
    }
    
    func setUpMap()
    {
        // Read defaults
        if defaults.boolForKey("defaultsAvailable") {
            let center = CLLocationCoordinate2D(latitude: defaults.doubleForKey("latitude"), longitude: defaults.doubleForKey("longitude"))
            let span = MKCoordinateSpan(latitudeDelta: defaults.doubleForKey("latitudeDelta"), longitudeDelta: defaults.doubleForKey("longitudeDelta"))
            let region = MKCoordinateRegionMake(center, span)
            
            mapView.setRegion(region, animated: true)
            mapView.centerCoordinate = center
        }
        else {
            startLocationUpdates()
        }
    }
    
    func dropAnnotation(loc: CLLocation) -> ()
    {
        getPlacemarkFromLocation(loc) { (placemark, error) -> () in
            if let err = error {
                let errorString = err.localizedDescription
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.presentAlert(errorString, completionHandler: { (bool) -> () in
                        if bool {
                            print("Try refetch")
                            self.dropAnnotation(loc)
                        }
                        else {
                            print("Bail out")
                            self.mapView.alpha = 1.0
                            self.activityIndicator.stopAnimating()
                            return
                        }
                    })
                })
            }
            
            //if placemart is valid
            if let local = placemark {
                // Check for valid postal code
                guard let _ = local.postalCode else {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        let errorString = "Invalid postal code"
                        
                        self.presentAlert(errorString, completionHandler: { (bool) -> () in
                            if bool {
                                print("Try refetch")
                                self.dropAnnotation(loc)
                            }
                            else {
                                print("Bail out")
                                self.mapView.alpha = 1.0
                                self.activityIndicator.stopAnimating()
                                return
                            }
                        })
                    })
                    
                    return
                }
                self.sharedContext.performBlock({ () -> Void in
                    //print(NSThread.isMainThread())
                    // Create Pin object
                    // using perfomBlock because Core Data is not thread safe
                    let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: self.sharedContext)
                    self.pin = Pin(entity:entity!, insertIntoManagedObjectContext: self.sharedContext)

                    self.pin.latitude = self.mapCoordinates.latitude
                    self.pin.longitude = self.mapCoordinates.longitude
                    self.pin.zipCode = local.postalCode
                    self.pin.title = local.locality
                    
                    self.client.getShelterInfo(self.pin, completion: { (errorstring) -> () in
                        if errorstring == nil {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.mapView.alpha = 1.0
                                self.activityIndicator.stopAnimating()
                                
                                // add map annotation
                                self.mapView.addAnnotation(self.pin)
                                self.editButton.enabled = true
                                
                            })
                        }
                    })
                })
            }
        }
    }
    
    func getPlacemarkFromLocation(location: CLLocation, handler: (CLPlacemark?, NSError?) -> ())
    {
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) -> Void in
            if let err = error {
                print("Reverse Geocode failed: \(error!.localizedDescription)")
                return handler(nil, err)
            }
            else {
                if let placemark = placemarks?.first {
                    return handler(placemark, nil)
                }
            }
            
            return handler(nil, nil)
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
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing {
            navigationItem.title = "Tap to delete pins"
        }
        else {
            navigationItem.title = "Purrfect Companion"
        }
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "shelterListSegueID" {
            let pinObj = sender as! Pin
            let vc = segue.destinationViewController as! ShelterListViewController
            
            vc.pin = pinObj
            vc.mapCoordinates = mapCoordinates
        }
    }
    
    // MARK: - MapView Delegate
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView)
    {
        if editing {
            let pin = view.annotation as! Pin
            
            // Keep a reference to the shelter IDs
            // in order to delete folder which contained images
            var ids = [String]()
            let shelters = pin.shelters as! Set<Shelter>
            
            for shelterid in shelters {
                ids.append(shelterid.id!)
            }
            
            sharedContext.deleteObject(pin)
            mapView.removeAnnotation(pin)
            
            CoreDataStack.sharedInstance().saveContext()
            
            // Remove empty folders
            for i in ids {
                Utilities.removeDirectory(i)
            }
            
            // Disable the edit button
            if mapView.annotations.isEmpty {
                setEditing(false, animated: true)
                editButton.enabled = false
            }
        }
        else {
            let pinView = view.annotation as! Pin
        
            mapView.deselectAnnotation(view.annotation, animated: true)
            pinLocation = (view.annotation?.title)!
            
            performSegueWithIdentifier("shelterListSegueID", sender: pinView)
        }
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool)
    {
        // Set defaults
        defaults.setBool(true, forKey: "defaultsAvailable")
        defaults.setDouble(mapView.region.span.latitudeDelta, forKey: "latitudeDelta")
        defaults.setDouble(mapView.region.span.longitudeDelta, forKey: "longitudeDelta")
        defaults.setDouble(mapView.region.center.latitude, forKey: "latitude")
        defaults.setDouble(mapView.region.center.longitude, forKey: "longitude")
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        if annotation is MKUserLocation {
            return nil
        }
        
        var annView = mapView.dequeueReusableAnnotationViewWithIdentifier(ANNOTATION_IDENTIFIER) as? MKPinAnnotationView
        
        if annView == nil {
            annView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: ANNOTATION_IDENTIFIER)
            annView!.canShowCallout = false
            annView!.animatesDrop = true
        }
        else {
            annView!.annotation = annotation
        }
        
        return annView
    
    }
    
    // MARK: - LocationManager Delegate
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus)
    {
        if status == .AuthorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let span = MKCoordinateSpan(latitudeDelta: 35, longitudeDelta: 35)
        let region:MKCoordinateRegion = MKCoordinateRegionMake((locations.first?.coordinate)!, span)
        
        mapView.setRegion(region, animated: true)
        locationManager?.stopUpdatingLocation()
    }
    
    func startLocationUpdates()
    {
        // Create the location manager if this object does not
        // already have one.
        
        if locationManager == nil {
            locationManager = CLLocationManager()
        }
        
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager?.requestWhenInUseAuthorization()
        }
        
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
