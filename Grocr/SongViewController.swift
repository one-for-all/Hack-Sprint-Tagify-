//
//  SongViewController.swift
//  Grocr
//
//  Created by 迦南 on 5/16/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import UIKit

class SongViewController: UIViewController, UITextFieldDelegate {
    
    
    @IBOutlet weak var tableView: UITableView!
    let songCellIdentifier = "SongCell"
    @IBOutlet weak var tagView: UIView!
    @IBOutlet weak var tagViewSongImageView: UIImageView!
    @IBOutlet weak var tagViewSongLabel: UILabel!
    @IBOutlet weak var addTagTextField: UITextField!
    
    @IBOutlet weak var tagViewTopLayoutConstraint: NSLayoutConstraint!
    
    
    var currentSelectedSong: Song = Song(name: "") {
        didSet {
            tagViewSongLabel.text = currentSelectedSong.name
            tagViewSongImageView.image = UIImage(named: currentSelectedSong.imageSource)
        }
    }
    
    @IBOutlet weak var collectionView: CollectionView!
    let tagCellReuseIdentifier = "TagReuseCell"
    
    let slideAnimationDuration = 0.25
    
    @IBOutlet weak var searchSongTextField: UITextField!

    let allSongNames: [String] = [
        "Bruno Mars - That’s What I Like",
        "Ed Sheeran - Shape of You [Official Video]",
        "Magic! - Rude",
        "Bruno Mars - 24K Magic",
        "Maroon 5 - Don't Wanna Know",
        "Ariana Grande - Into You",
        "The Weeknd - The Hills",
        "Taylor Swift - Wildest Dreams",
        "Mark Ronson - Uptown Funk ft. Bruno Mars"
    ]
    var allSongList = [Song]()
    var searchedSongList = [Song]()
    
    @IBAction func searchSongEditDidEnd(_ sender: UITextField) {
        print("End Editing!")
        var newSongList = [Song]()
        if let searchString = sender.text {
            if searchString == "" {
                searchedSongList = allSongList
            } else {
                for song in allSongList {
                    if song.name.range(of:searchString) != nil{
                        newSongList.append(song)
                    }
                }
                searchedSongList = newSongList
            }
        }
        tableView.reloadData()
    }

    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
        print("Pressed Return!")
        textField.resignFirstResponder()
        return true
    }
  
  
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.dataSource = self
        tableView.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        for song in allSongNames {
            var newSong = Song(name: song)
            newSong.tags = ["#Pop", "#Wedding", "#Shower", "#Mona Lisa"]
            if song.range(of: "Bruno Mars") != nil {
                newSong.imageSource = "BrunoMars.jpg"
            } else if song.range(of: "Magic!") != nil {
                newSong.imageSource = "Magic!.png"
            } else if song.range(of: "Taylor Swift") != nil {
                newSong.imageSource = "TaylorSwift.jpg"
            } else if song.range(of: "Maroon 5") != nil {
                newSong.imageSource = "Maroon5.jpg"
            }
            allSongList.append(newSong)
        }
        searchedSongList = allSongList
        
        //Hide tagView initially
//        self.tagView.frame.origin.y = self.view.frame.height
        
        //set collectionViewCell to autoresize
        if let cvl = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            cvl.estimatedItemSize = CGSize(width: 78, height: 59)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
    @IBAction func logOffPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func closeTagView(_ sender: UIButton) {
        let origin_y = view.frame.height
        guard let current_color = self.view.backgroundColor else { return }
        UIView.animate(withDuration: slideAnimationDuration) {
            self.tagView.frame.origin.y = origin_y
            self.view.backgroundColor = current_color.withAlphaComponent(1)
            self.navigationController?.navigationBar.alpha = 1
        }
    }
    
    @IBAction func showTagView(_ sender: Any) {
        if let button = sender as? UIButton {
            if let superView = button.superview {
                if let cell = superView.superview as? SongTableViewCell {
                    currentSelectedSong = cell.song
                }
            }
        }
        updateCollectionView()
        let origin_y = view.frame.height-self.tagView.frame.height
        self.tagView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 0).isActive = true
        guard let currentViewColor = view.backgroundColor else { print("Error getting current color!"); return}
        let newAlphaValue: CGFloat = 0.8
        let newColor = currentViewColor.withAlphaComponent(newAlphaValue)
        UIView.animate(withDuration: slideAnimationDuration) {
//            self.view.layoutIfNeeded()
            self.tagView.frame.origin.y = origin_y
            self.view.backgroundColor = newColor
            self.navigationController?.navigationBar.alpha = newAlphaValue
        }
    }
    
    
    @IBAction func addTagButtonPressed(_ sender: Any) {
        if let text = addTagTextField.text {
            if text != "" {
                currentSelectedSong.tags.insert("\(text)")
                updateCollectionView()
            }
        }
    }
    
    
}

extension SongViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchedSongList.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: songCellIdentifier, for: indexPath) as! SongTableViewCell
        cell.song = searchedSongList[indexPath.row]
//        cell.songImageView.image = UIImage(named: searchedSongList[indexPath.row].imageSource)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

extension SongViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentSelectedSong.tags.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: tagCellReuseIdentifier, for: indexPath)
        cell.layer.borderWidth = 2
        if let newCell = cell as? CollectionViewCell {
            let tags = currentSelectedSong.tags
            newCell.tagLabel.text = tags[tags.index(tags.startIndex, offsetBy: indexPath.row)]
        }
        return cell
    }
    func removeTag() {
        print("current cell: \(collectionView.currentSelectedCell.tagLabel.text)")
        if let tagToRemove = collectionView.currentSelectedCell.tagLabel.text {
            self.currentSelectedSong.tags.remove(tagToRemove)
            updateCollectionView()
        }
    }
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if collectionView.isFirstResponder {
            if action == #selector(self.removeTag) {
                return true
            }
        }
        return false
    }
    func updateCollectionView() {
        self.collectionView.reloadSections(IndexSet(integer: 0))
    }
}
