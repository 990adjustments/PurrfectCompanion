//
//  ShelterViewCell.swift
//  PurrfectCompanion
//
//  Created by Erwin Santacruz on 11/23/15.
//  Copyright © 2015 Erwin Santacruz. All rights reserved.
//

import UIKit

class ShelterViewCell: UICollectionViewCell {
    
    var imageURL: String!
    
    @IBOutlet weak var photoCell: UIImageView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! {
        didSet {
            self.activityIndicator.hidesWhenStopped = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        photoCell.image = nil
    }
}
