//
//  FollowingTableViewCell.swift
//  Tagify
//
//  Created by 迦南 on 5/27/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import UIKit

class FollowingTableViewCell: UITableViewCell {
    
    @IBOutlet weak var userIconImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
      userIconImageView.layer.cornerRadius = userIconImageView.frame.width/2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
