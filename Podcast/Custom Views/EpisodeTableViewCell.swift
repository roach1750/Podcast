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
    @IBOutlet var downloadView: UIView!
    @IBOutlet var progressBar: UIProgressView!
    @IBOutlet var downloadProgressLabel: UILabel!
    
    var episode: Episode? 
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func updateDisplay(progress: Float, totalSize : String) {
        progressBar.progress = progress
        downloadProgressLabel.text = String(format: "%.1f%% of %@", progress * 100, totalSize)
    }
    
    
    
}
