//
//  SongViewController.swift
//  Grocr
//
//  Created by 迦南 on 5/16/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import UIKit
import Firebase
import Foundation
import StoreKit
import MediaPlayer

class SongViewController: UIViewController, UITextFieldDelegate {
    
    var userRef: FIRDatabaseReference!
    var tagRef: FIRDatabaseReference!
    var user: User!
    
    @IBOutlet weak var tableView: UITableView!
    let songCellIdentifier = "SongCell"
    @IBOutlet weak var tagView: UIView!
    @IBOutlet weak var tagViewSongImageView: UIImageView!
    @IBOutlet weak var tagViewSongLabel: UILabel!
    @IBOutlet weak var addTagTextField: UITextField!
    
    @IBOutlet weak var tagViewSlideUpConstraint: NSLayoutConstraint!
    @IBOutlet weak var tagViewSlideDownConstraint: NSLayoutConstraint!
    
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
        "Bruno Mars - That's What I Like",
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
        print("End Editing! Starting Searching")
        var newSongList = [Song]()
        if let searchString = sender.text {
            if searchString == "" {
                newSongList = allSongList
            } else if searchString[searchString.startIndex] == "#" {
                print("Searching Hashtag!")
                let searchStringArr = searchString.components(separatedBy: "#").dropFirst()
                for song in allSongList {
                    var flag = true
                    for tag in searchStringArr {
                        if !(song.tags.contains("#\(tag)")) {
                            flag = false
                        }
                    }
                    if (flag) {
                        newSongList.append(song)
                    }
                }
            } else {
                for song in allSongList {
                    if song.name.lowercased().range(of:searchString.lowercased()) != nil{
                        newSongList.append(song)
                    }
                }
            }
            searchedSongList = newSongList
            tableView.reloadData()
        }
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
        tableView.allowsSelection = true
        tableView.isUserInteractionEnabled = true
        tagViewSongImageView.layer.cornerRadius = tagViewSongImageView.frame.width/2
//        self.tableView.allowsSelectionDuringEditing = YES;
        collectionView.dataSource = self
        collectionView.delegate = self
        
        initializeDefaultAllSongList()
        searchedSongList = allSongList
        
        //Hide tagView initially
//        self.tagView.frame.origin.y = self.view.frame.height
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.delegate = self
        view.addGestureRecognizer(tap)  // Allows dismissal of keyboard on tap anywhere on screen besides the keyboard itself
        //set collectionViewCell to autoresize
        if let cvl = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            cvl.estimatedItemSize = CGSize(width: 78, height: 59)
        }
        FIRAuth.auth()?.addStateDidChangeListener {auth, user in
            guard let user = user else { print("no user!"); return }
            self.user = User(authData: user)
            self.userRef = FIRDatabase.database().reference(withPath: "users/\(user.uid)")
            self.tagRef = FIRDatabase.database().reference(withPath: "tags")
            self.userRef.observe(.value, with: { (snapshot) in
                if !snapshot.hasChild("email") {
                    self.userRef.child("email").setValue(user.email!)
                }
                if snapshot.hasChild("songs") {
                    var newSongs = [Song]()
                    for song in snapshot.childSnapshot(forPath: "songs").children.allObjects as! [FIRDataSnapshot] {
                        let newSong = Song(snapshot: song)
                        newSongs.append(newSong)
                    }
                    self.initializeAllSongList(songs: newSongs)
                    self.searchedSongList = self.allSongList
                } else {
                    for song in self.allSongList {
                        self.userRef.child("songs/\(song.key)").setValue(song.toAnyObject())
                    }
                }
                self.tableView.reloadData()
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
    @IBAction func logOffPressed(_ sender: UIButton) {
        try! FIRAuth.auth()!.signOut()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func closeTagView(_ sender: UIButton) {
        let origin_y = view.frame.height
        tagViewSlideDownConstraint.isActive = true
        tagViewSlideUpConstraint.isActive = false
        guard let current_color = self.view.backgroundColor else { return }
        UIView.animate(withDuration: slideAnimationDuration) {
            self.tagView.frame.origin.y = origin_y
            self.view.backgroundColor = current_color.withAlphaComponent(1)
            self.navigationController?.navigationBar.alpha = 1
        }
    }
    
    @IBAction func showTagView(_ sender: Any) {
        dismissKeyboard()
        if let button = sender as? UIButton {
            if let superView = button.superview {
                if let cell = superView.superview as? SongTableViewCell {
                    currentSelectedSong = cell.song
                }
            }
        }
        UIView.performWithoutAnimation {
            updateCollectionView()
        }
        let origin_y = view.frame.height-self.tagView.frame.height
        tagViewSlideDownConstraint.isActive = false
        tagViewSlideUpConstraint.isActive = true
        guard let currentViewColor = view.backgroundColor else { print("Error getting current color!"); return}
        let newAlphaValue: CGFloat = 0.8
        let newColor = currentViewColor.withAlphaComponent(newAlphaValue)
        UIView.animate(withDuration: slideAnimationDuration) {
            self.tagView.frame.origin.y = origin_y
            self.view.backgroundColor = newColor
            self.navigationController?.navigationBar.alpha = newAlphaValue
        }
    }
    
    @IBAction func addTagButtonPressed(_ sender: Any) {
        if let text = addTagTextField.text {
            if text != "" {
                currentSelectedSong.tags.insert("\(text)")
                let strippedHashTag = text.substring(from: text.index(text.startIndex, offsetBy: 1))
                self.userRef.child("songs/\(currentSelectedSong.key)/tags").updateChildValues([strippedHashTag: true])
                
                let songName = currentSelectedSong.name
                self.tagRef.child("\(strippedHashTag)").updateChildValues([songName: true])
                updateCollectionView()
            }
        }
    }
    
}


//Related to TableView
extension SongViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchedSongList.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: songCellIdentifier, for: indexPath) as! SongTableViewCell
        cell.songImageView.layer.cornerRadius = cell.songImageView.frame.size.width/2
        cell.song = searchedSongList[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismissKeyboard()
        if let cell = tableView.cellForRow(at: indexPath) as? SongTableViewCell {
            appleMusicCheckIfDeviceCanPlayback()
            appleMusicRequestPermission()
            appleMusicFetchStorefrontRegion()
                    //playSong(song: cell.song)
            appleMusicPlayTrackId(ids: [cell.song.name])
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100;
    }
}


//Related to CollectionView
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
            let strippedHashTag = tagToRemove.substring(from: tagToRemove.index(tagToRemove.startIndex, offsetBy: 1))
            self.userRef.child("songs/\(currentSelectedSong.key)/tags").updateChildValues([strippedHashTag: NSNull()])
            
            let songName = currentSelectedSong.name
            self.tagRef.child("\(strippedHashTag)").updateChildValues([songName: NSNull()])
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

extension SongViewController: UIGestureRecognizerDelegate { //Related to Tap Gesture
    // UIGestureRecognizerDelegate method
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.isDescendant(of: self.tableView) == true {
            return false
        }
        return true
    }
    func dismissKeyboard() {
        searchSongTextField.resignFirstResponder()
        addTagTextField.resignFirstResponder()
    }
}

extension SongViewController {
    func initializeDefaultAllSongList() {
        allSongList = []
        for (index, song) in allSongNames.enumerated() {
            let newSong = Song(name: song,  key:"\(index)")
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
    }
    func initializeAllSongList(songs: [Song]) {
        allSongList = []
        for song in songs {
            let songName = song.name
            if songName.range(of: "Bruno Mars") != nil {
                song.imageSource = "BrunoMars.jpg"
            } else if songName.range(of: "Magic!") != nil {
                song.imageSource = "Magic!.png"
            } else if songName.range(of: "Taylor Swift") != nil {
                song.imageSource = "TaylorSwift.jpg"
            } else if songName.range(of: "Maroon 5") != nil {
                song.imageSource = "Maroon5.jpg"
            }
            allSongList.append(song)
        }
    }
}

extension SongViewController { //Related to Music

    // Check if the device is capable of playback
    func appleMusicCheckIfDeviceCanPlayback() -> Bool {
        let serviceController = SKCloudServiceController()
        var canPlayback = false
        serviceController.requestCapabilities(completionHandler: { (capability: SKCloudServiceCapability, error: Error?) in
            
            switch capability {
        
            case SKCloudServiceCapability.musicCatalogPlayback:
                print("The user has an Apple Music subscription and can playback music!")
                canPlayback = true
                return
                
            case SKCloudServiceCapability.addToCloudMusicLibrary:
                
                print("The user has an Apple Music subscription, can playback music AND can add to the Cloud Music Library")
                canPlayback = true
                return
                
            default:
                print("The user doesn't have an Apple Music subscription available. Now would be a good time to prompt them to buy one?")
                canPlayback = false
                return
                
            }
            
        })
        return canPlayback
    }
    
    
    // Request permission from the user to access the Apple Music library
    func appleMusicRequestPermission() -> Bool {
        var havePermission = false
        switch SKCloudServiceController.authorizationStatus() {
        case .authorized:
            print("The user's already authorized - we don't need to do anything more here, so we'll exit early.")
            return true
            
        case .denied:
            print("The user has selected 'Don't Allow' in the past - so we're going to show them a different dialog to push them through to their Settings page and change their mind, and exit the function early.")
            // Show an alert to guide users into the Settings
            return false
            
        case .notDetermined:
            print("The user hasn't decided yet - so we'll break out of the switch and ask them.")
            break
            
        case .restricted:
            print("User may be restricted; for example, if the device is in Education mode, it limits external Apple Music usage. This is similar behaviour to Denied.")
            return false
        }
        
        SKCloudServiceController.requestAuthorization { (status:SKCloudServiceAuthorizationStatus) in
            
            switch status {
                
            case .authorized:
                print("All good - the user tapped 'OK', so you're clear to move forward and start playing.")
                havePermission = true
                
            case .denied:
                print("The user tapped 'Don't allow'. Read on about that below...")
                
            case .notDetermined:
                print("The user hasn't decided or it's not clear whether they've confirmed or denied.")
                
            default: break
                
            }
            
        }
        return havePermission
    }
    
    // Fetch the user's storefront ID
    func appleMusicFetchStorefrontRegion() {
        
        let serviceController = SKCloudServiceController()
        serviceController.requestStorefrontIdentifier(completionHandler: { (storefrontId:String?, err:Error?) in
            
            guard err == nil else {
                print("An error occured when getting storefront ID.")
                return
            }
            
            guard let storefrontId = storefrontId, storefrontId.characters.count >= 6 else {
                print("Invalid storefrontID.")
                return
            }
            
            let indexRange = storefrontId.index(storefrontId.startIndex, offsetBy:0)..<storefrontId.index(storefrontId.startIndex, offsetBy:5)
            let trimmedId = storefrontId.substring(with: indexRange)
            
            print("Success! The user's storefront ID is: \(trimmedId)")
            
        })
        
    }
    
    // Choose Player type & Play
    func appleMusicPlayTrackId(ids:[String]) {
        let applicationMusicPlayer = MPMusicPlayerController.applicationMusicPlayer()
        //applicationMusicPlayer.setQueueWithStoreIDs(ids)
        applicationMusicPlayer.setQueueWithStoreIDs(["966997496"])
        applicationMusicPlayer.play()
        print("Play \(ids)")
        //print("Play \(song.name)")
    }
    
}
