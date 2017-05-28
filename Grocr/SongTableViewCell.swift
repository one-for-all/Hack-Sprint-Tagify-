//
//  SongTableViewCell.swift
//  Grocr
//
//  Created by 迦南 on 5/16/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import UIKit

class SongTableViewCell: UITableViewCell {
    
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var songImageView: UIImageView!
    @IBOutlet weak var songTagsLabel: UILabel!
    
    var song: Song = Song(name: "") {
        didSet {
            songNameLabel.text = song.name
            let firstFourLetters = song.imageSource.index(song.imageSource.startIndex, offsetBy:4)
            if song.imageSource.substring(to: firstFourLetters) == "http" {
                let url = NSURL(string: song.imageSource)
                let data = NSData(contentsOf: url as! URL)
                songImageView.image = UIImage(data: data as! Data)
            } else {
                songImageView.image = UIImage(named: song.imageSource)
            }
            var text: String = "";
            for tag in song.tags {
                text += " \(tag)"
            }
            songTagsLabel.text = text
        }
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
