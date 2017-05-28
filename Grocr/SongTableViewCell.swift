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
    
    var song: Song = Song(trackId: "") {
        didSet {
            songNameLabel.text = song.name
            var text: String = "";
            for tag in song.tags {
                text += " \(tag)"
            }
            songTagsLabel.text = text
//            let firstFourLetters = song.imageSource.index(song.imageSource.startIndex, offsetBy:4)
//            if song.imageSource.substring(to: firstFourLetters) == "http" {
//                let url = URL(string: song.imageSource)
//                let data = try? Data(contentsOf: url!)
//                songImageView.image = UIImage(data: data!)
//            } else {
//                songImageView.image = UIImage(named: song.imageSource)
//            }
            let firstFourLetters = song.imageSource.index(song.imageSource.startIndex, offsetBy:4)
            if song.imageSource.substring(to: firstFourLetters) == "http" {
                let url = URL(string: song.imageSource)
                DispatchQueue.global().async {
                    let data = try? Data(contentsOf: url!)
                    DispatchQueue.main.async {
                        self.songImageView.image = UIImage(data: data!)
                    }
                }
            } else {
                songImageView.image = UIImage(named: song.imageSource)
            }

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
