//
//  PetViewController.swift
//  PurrfectCompanion
//
//  Created by Erwin Santacruz on 12/27/15.
//  Copyright © 2015 Erwin Santacruz. All rights reserved.
//

import UIKit
import CoreData

class PetViewController: UIViewController {

    var cat: Cat!
    var noData: Bool!
    
    // UI outlets
    @IBOutlet weak var petImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var sexLabel: UILabel!
    @IBOutlet weak var shelterNameLabel: UILabel!
    @IBOutlet weak var shelterIDLabel: UILabel!
    
    var shareButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        noData = false
        
        setupUI()
        setupData()
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if noData == true {
            return
        }
        
        let labels = [nameLabel, shelterIDLabel, ageLabel, sexLabel]
        var step = 0.2
        
        for label in labels {
            UIView.animateWithDuration(0.3 + step, animations: { () -> Void in
                label.alpha = 1.0
            })
            
            step += 0.4
        }
    }
    
    func setupData()
    {
        let id = cat?.id!
        let imagePath = Utilities.fileOperations.CACHE_DIR.URLByAppendingPathComponent((cat.shelter?.id!)!+"/"+id!)
        
        if let imageData = Utilities.fileOperations.FILE_MANAGER.contentsAtPath(imagePath.path!) {
            let img = UIImage(data: imageData)
            
            petImage.image = img
            
            shelterNameLabel.text = cat.shelter?.name
            nameLabel.text = cat.name
            shelterIDLabel.text = cat.id
            ageLabel.text = cat.age
            sexLabel.text = cat.sex
            
            nameLabel.alpha = 0
            shelterIDLabel.alpha = 0
            ageLabel.alpha = 0
            sexLabel.alpha = 0
        }
        else {
            petImage.image = UIImage(named: "no-pictures")
            shelterNameLabel.text = "Unable to download pet information."
            nameLabel.alpha = 0
            shelterIDLabel.alpha = 0
            ageLabel.alpha = 0
            sexLabel.alpha = 0
            
            noData = true
            shareButton.enabled = false
            navigationItem.title = ""
        }
    }
    
    func setupUI()
    {
        shareButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action , target: self, action: Selector("sharePet"))
        navigationItem.setRightBarButtonItem(shareButton, animated: true)
        shareButton.enabled = true
        navigationItem.title = cat.name
        
        // Remove text from back button
        navigationController?.navigationBar.topItem!.title = ""
    }
    
    func sharePet()
    {
        if noData == true {
            return
        }
        
        let petInfo = "Hi! I'm \(cat.name!). I'm at \(cat.shelter!.name!) in \(cat.shelter!.location!). Please adopt me!"
        let activityVC = UIActivityViewController(activityItems: [petInfo, petImage.image!], applicationActivities: nil)
        
        activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAssignToContact, UIActivityTypeOpenInIBooks]
        
        navigationController?.presentViewController(activityVC, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
