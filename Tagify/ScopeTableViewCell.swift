//
//  ScopeTableViewCell.swift
//  Tagify
//
//  Created by 迦南 on 5/27/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import UIKit

class ScopeTableViewCell: UITableViewCell {
  
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var usernameLabel: UILabel!
  let storageRef = Storage.storage().reference()
  var user = TagifyUserForDisplay(uid: "") {
    didSet {
      usernameLabel.text = user.username
      iconImageView.image = user.userIcon
      self.accessoryType = user.listenedTo == true ? .checkmark : .none
    }
  }
  
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
      iconImageView.layer.cornerRadius = iconImageView.frame.width/2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
