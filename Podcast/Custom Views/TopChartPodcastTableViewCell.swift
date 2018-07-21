//
//  TopChartPodcastTableViewCell.swift
//  Podcast
//
//  Created by Andrew Roach on 5/5/18.
//  Copyright © 2018 Andrew Roach. All rights reserved.
//

import UIKit

class TopChartPodcastTableViewCell: UITableViewCell {

    @IBOutlet var rankingLabel: UILabel!
    @IBOutlet var podcastImage: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
