//
//  PodcastTableViewCell.swift
//  Podcast
//
//  Created by Andrew Roach on 10/11/17.
//  Copyright © 2017 Andrew Roach. All rights reserved.
//

import UIKit

class EpisodeTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var specsLabel: UILabel!
    @IBOutlet weak var longDescriptionLabel: UILabel!
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
