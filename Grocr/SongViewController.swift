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
import Alamofire

class SongViewController: UIViewController, UITextFieldDelegate {
    
    var currentUserRef: DatabaseReference!
    var currentUserTagRef: DatabaseReference!
    let userProfilesRef: DatabaseReference! = Database.database().reference(withPath: "userProfiles")
    var currentUser: TagifyUser!
    
    @IBOutlet weak var searchSongTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    let songCellIdentifier = "SongCell"
    @IBOutlet weak var tagView: UIView!
    @IBOutlet weak var tagViewSongImageView: UIImageView!
    @IBOutlet weak var tagViewSongLabel: UILabel!
    @IBOutlet weak var addTagTextField: UITextField!
    @IBOutlet weak var collectionView: CollectionView!
    let tagCellReuseIdentifier = "TagReuseCell"
    let slideAnimationDuration = 0.25
    
    @IBOutlet weak var tagViewSlideUpConstraint: NSLayoutConstraint!
    @IBOutlet weak var tagViewSlideDownConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var playButton: UIButton!
    
    var currentSelectedSong: Song = Song(name: "") {
        didSet {
            tagViewSongLabel.text = currentSelectedSong.name
            tagViewSongImageView.image = UIImage(named: currentSelectedSong.imageSource)
        }
    }
    var isPlaying = false
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
            searchedSongList = songList(withSearchString: searchString)
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
        
        searchSongTextField.returnKeyType = .search
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = true
        tableView.isUserInteractionEnabled = true
        tagViewSongImageView.layer.cornerRadius = tagViewSongImageView.frame.width/2
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
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else { print("no user!"); return }
            self.currentUser = TagifyUser(authData: user)
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.currentUser = self.currentUser
            self.currentUserRef = Database.database().reference(withPath: "users/\(user.uid)")
            self.currentUserTagRef = Database.database().reference(withPath: "tags")
            self.initializeUserProfile(user: user)
            self.initializeCurrentUserSongList()
            self.initializeFollowingForCurrentUser()
            self.initializeFollowedByForCurrentUser()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        closeTagView()
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
                if isValid(tag: text) {
                    currentSelectedSong.tags.insert("\(text)")
                    let strippedHashTag = text.substring(from: text.index(text.startIndex, offsetBy: 1))
                    self.currentUserRef.child("songs/\(currentSelectedSong.key)/tags").updateChildValues([strippedHashTag: true])
                    
                    let songName = currentSelectedSong.name
                    self.currentUserTagRef.child("\(strippedHashTag)").updateChildValues([songName: true])
                    updateCollectionView()
                } else {
                    print("invalid tag")
                    let alert = UIAlertController(title: "Invalid Tag", message: "A tag should not end with space", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    @IBAction func playButtonPressed(_ sender: Any) {
        if isPlaying {
            pausePlay()
            isPlaying = false
            playButton.setImage(UIImage(named: "playButton.png"), for: .normal)
        } else {
            continuePlay()
            isPlaying = true
            playButton.setImage(UIImage(named: "stopButton.png"), for: .normal)
        }
    }
    @IBAction func forwardButtonPressed(_ sender: Any) {
        playNext()
    }
    @IBAction func backwardButtonPressed(_ sender: Any) {
        playPrevious()
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
            authorizeAppleMusic()
            searchBarSearchButtonClicked(song: cell.song)
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
            self.currentUserRef.child("songs/\(currentSelectedSong.key)/tags").updateChildValues([strippedHashTag: NSNull()])
            
            let songName = currentSelectedSong.name
            self.currentUserTagRef.child("\(strippedHashTag)").updateChildValues([songName: NSNull()])
            updateCollectionView()
        }
    }
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if collectionView.isFirstResponder {
            switch  action {
            case #selector(self.removeTag), #selector(self.searchSongs):
                return true
            default:
                return false
            }
        }
        return false
    }
    func updateCollectionView() {
        self.collectionView.reloadSections(IndexSet(integer: 0))
    }
    func isValid(tag: String) -> Bool {
        if tag[tag.index(before: tag.endIndex)] == " " {
            return false
        }
        return true
    }
    func closeTagView() {
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
    func searchSongs() {
        let searchString = collectionView.currentSelectedCell.tagLabel.text!
        searchedSongList = songList(withSearchString: searchString)
        tableView.reloadData()
        searchSongTextField.text = searchString
        closeTagView()
        print("search songs with tag \(collectionView.currentSelectedCell.tagLabel.text!)")
    }
}

extension SongViewController { // related to search
    func songList(withSearchString searchString: String) -> [Song] {
        var searchedSongList = [Song]()
        if searchString == "" {
            searchedSongList = allSongList
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
                    searchedSongList.append(song)
                }
            }
        } else {
            for song in allSongList {
                if song.name.lowercased().range(of:searchString.lowercased()) != nil{
                    searchedSongList.append(song)
                }
            }
        }
        return searchedSongList
    }
}

extension SongViewController { // two methods for initializing song lists depending on whether new user
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

extension SongViewController { // initialize current user info with data fram database & fill in missing data in database
    func initializeFollowingForCurrentUser() {
        let currentUserFollowingRef = self.userProfilesRef.child("\(self.currentUser.uid)/following")
        currentUserFollowingRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                for uid in snapshot.value as! [String: Bool] {
                    print("following : \(uid.key)")
                    self.currentUser.following.insert(TagifyUser(uid: uid.key))
                }
            }
        })
    }
    func initializeFollowedByForCurrentUser() {
        let currentUserFollowedRef = self.userProfilesRef.child("\(self.currentUser.uid)/followedBy")
        currentUserFollowedRef.observeSingleEvent(of: .value, with: { (snapshot) in
            print("current uid is : \(self.currentUser.uid)")
            if snapshot.exists() {
                for uid in snapshot.value as! [String: Bool] {
                    print("followed by : \(uid.key)")
                    self.currentUser.followedBy.insert(TagifyUser(uid: uid.key))
                }
            }
        })
    }
    func initializeUserProfile(user: User) {
        let currentUserProfileRef = self.userProfilesRef.child("\(self.currentUser.uid)")
        currentUserProfileRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if !snapshot.hasChild("email") {
                currentUserProfileRef.child("email").setValue(user.email!)
            }
            if !snapshot.hasChild("username") {
                currentUserProfileRef.child("username").setValue(user.email!)
            } else {
                self.currentUser.username = snapshot.childSnapshot(forPath: "username").value as! String
            }
        })
    }
    func initializeCurrentUserSongList() {
        self.currentUserRef.observe(.value, with: { (snapshot) in
            if !snapshot.hasChild("email") {
                self.currentUserRef.child("email").setValue(self.currentUser.email)
            }
            if snapshot.hasChild("songs") {
                var newSongs = [Song]()
                for song in snapshot.childSnapshot(forPath: "songs").children.allObjects as! [DataSnapshot] {
                    let newSong = Song(snapshot: song)
                    newSongs.append(newSong)
                }
                self.initializeAllSongList(songs: newSongs)
                self.searchedSongList = self.allSongList
            } else {
                for song in self.allSongList {
                    self.currentUserRef.child("songs/\(song.key)").setValue(song.toAnyObject())
                }
            }
            self.tableView.reloadData()
        })
    }
}

extension SongViewController { //Related to Music
    
    func authorizeAppleMusic() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        //Ask user for for Apple Music access
        SKCloudServiceController.requestAuthorization { (status) in
            if status == .authorized {
                let controller = SKCloudServiceController()
                //Check if user is a Apple Music member
                controller.requestCapabilities(completionHandler: ({ (capabilities, error) in
                    if error != nil {
                        DispatchQueue.main.async(execute: {
                            //self.showAlert("Capabilites error", error: "You must be an Apple Music member to use this application")
                            print("You must be an Apple Music member to use this application")
                        })
                    }
                }))
            } else {
                DispatchQueue.main.async(execute: {
                    //self.showAlert("Denied", error: "User has denied access to Apple Music library")
                    print("User has denied access to Apple Music library")
                })
            }
        }
    }
    
    // Fetch the user's storefront ID
    func appleMusicFetchStorefrontRegion() -> String {
        
        let serviceController = SKCloudServiceController()
        var userStorefrontId = ""
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
            userStorefrontId = trimmedId
            return
        })
        return userStorefrontId
    }
    
    // Choose Player type & Play
    func appleMusicPlayTrackId(trackId: String) {
        
        let applicationMusicPlayer = MPMusicPlayerController.applicationMusicPlayer()
        //applicationMusicPlayer.setQueueWithStoreIDs(ids)
        applicationMusicPlayer.setQueueWithStoreIDs([trackId])
        applicationMusicPlayer.prepareToPlay()
        applicationMusicPlayer.play()
        //print("Play \(song.name)")
    }
    func pausePlay() {
        print("Music paused")
    }
    //Search iTunes and display results in table view
    func searchItunes(searchTerm: String, storefrontId: String) {
        Alamofire.request("https://itunes.apple.com/search?term=\(searchTerm)&entity=song&s=\(storefrontId)")
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success:
                    if let responseData = response.result.value as? NSDictionary {
                        if let songResults = responseData.value(forKey: "results") as? [NSDictionary] {
                            //self.tableData = songResults
                            //self.tableView!.reloadData()
                            print("https://itunes.apple.com/search?term=\(searchTerm)&entity=song&s=\(storefrontId)")
                            print(responseData)
                            print(songResults)
                            let trackNum = songResults[0]["trackId"] as! NSNumber
                            let track = "\(trackNum)"
                            self.appleMusicPlayTrackId(trackId: track)
                        }
                    }
                case .failure(let error):
                    //self.showAlert("Error", error: error.description)
                    print("Failed to search itunes.")
                }
        }
    }
    
    func removeSpecialChars(str: String) -> String {
        let chars = Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890".characters)
        return String(str.characters.filter{chars.contains($0)})
    }
    
    func searchBarSearchButtonClicked(song: Song) {
        //Search iTunes with user input
        let search = removeSpecialChars(str: song.name).replacingOccurrences(of: " ", with: "+")
        let region = appleMusicFetchStorefrontRegion()
        searchItunes(searchTerm: search, storefrontId: region)
        //song.resignFirstResponder()
    }
    
    /*
     //Display iTunes search results
     func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
     let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: nil)
     if let rowData: NSDictionary = self.tableData[indexPath.row] as? NSDictionary,
     urlString = rowData["artworkUrl60"] as? String,
     imgURL = NSURL(string: urlString),
     imgData = NSData(contentsOfURL: imgURL) {
     cell.imageView?.image = UIImage(data: imgData)
     cell.textLabel?.text = rowData["trackName"] as? String
     cell.detailTextLabel?.text = rowData["artistName"] as? String
     }
     return cell
     }
     //Add song to playback queue if user selects a cell
     func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
     let indexPath = tableView.indexPathForSelectedRow
     if let rowData: NSDictionary = self.tableData[indexPath!.row] as? NSDictionary, urlString = rowData["artworkUrl60"] as? String,
     imgURL = NSURL(string: urlString),
     imgData = NSData(contentsOfURL: imgURL) {
     queue.append(SongData(artWork: UIImage(data: imgData), trackName: rowData["trackName"] as? String, artistName: rowData["artistName"] as? String, trackId: String (rowData["trackId"]!)))
     //Show alert telling the user the song was added to the playback queue
     let addedTrackAlert = UIAlertController(title: nil, message: "Added track!", preferredStyle: .Alert)
     self.presentViewController(addedTrackAlert, animated: true, completion: nil)
     let delay = 0.5 * Double(NSEC_PER_SEC)
     let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
     dispatch_after(time, dispatch_get_main_queue(), {
     addedTrackAlert.dismissViewControllerAnimated(true, completion: nil)
     })
     tableView.deselectRowAtIndexPath(indexPath!, animated: true)
     }
     }
     */
    func continuePlay() {
        print("Music continued")
    }
    func playNext() {
        print("Play next song")
    }
    func playPrevious() {
        print("Play previous song")
    }
}
