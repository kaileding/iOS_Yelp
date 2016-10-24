//
//  BusinessCell.swift
//  Yelp
//
//  Created by DINGKaile on 10/22/16.
//  Copyright © 2016 Timothy Lee. All rights reserved.
//

import UIKit

class BusinessCell: UITableViewCell {

    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var ratingImageView: UIImageView!
    @IBOutlet weak var reviewsLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var categoriesLabel: UILabel!
    
    var business: Business! {
        didSet {
            self.nameLabel.text = business.name
            self.thumbImageView.setImageWith(business.imageURL!)
            self.categoriesLabel.text = business.categories
            self.addressLabel.text = business.address
            self.reviewsLabel.text = "\(business.reviewCount!) Reviews"
            self.ratingImageView.setImageWith(business.ratingImageURL!)
            self.distanceLabel.text = business.distance
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.thumbImageView.layer.cornerRadius = 3
        self.thumbImageView.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
