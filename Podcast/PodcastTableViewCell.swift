//
//  PodcastTableViewCell.swift
//  Podcast
//
//  Created by Andrew Roach on 10/19/17.
//  Copyright © 2017 Andrew Roach. All rights reserved.
//

import UIKit

class PodcastTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    @IBOutlet weak var podcastImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lastUpdatedLabel: UILabel!
    
}
