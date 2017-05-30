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
    @IBOutlet weak var songArtistLabel: UILabel!
    
    
    var song: Song = Song(trackId: "") {
        didSet {
            songNameLabel.text = song.name
            var text: String = "";
            songArtistLabel.text = song.artist
            for tag in song.tags {
                text += " #\(tag)"
            }
            songTagsLabel.text = text
            guard song.imageSource.characters.count >= 4 else {
                songImageView.image = UIImage(named: song.imageSource)
                return
            }
            let firstFourLetters = song.imageSource.index(song.imageSource.startIndex, offsetBy:4)
            if song.imageSource.substring(to: firstFourLetters) == "http" {
                let url = URL(string: song.imageSource)
                DispatchQueue.global().async {
                    let data = try? Data(contentsOf: url!)
                    DispatchQueue.main.async {
                        if let data = data {
                            self.songImageView.image = UIImage(data: data)
                        }
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
