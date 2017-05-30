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
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    let userProfilesRef: DatabaseReference! = Database.database().reference(withPath: "userProfiles")
    let userSongsRef: DatabaseReference! = Database.database().reference(withPath: "userSongs")
    let userTagsRef: DatabaseReference! = Database.database().reference(withPath: "userTags")
    let storage = Storage.storage()
    let storageRef: StorageReference! = Storage.storage().reference()
    var player: AVPlayer!
    var didCheckAndSuggestAppleMusicSignUp = false
    var didAskForMediaLibraryAccess = false
    var storefrontId = "143441"  // Default region is USA
    var authorizationStatus = false
    var appleMusicCapable = false
    var applicationMusicPlayer = MPMusicPlayerController.applicationMusicPlayer()
    var itunesSongList = [Song]()
    var nowPlayingIndex = -1
    var playlist = [Song]()
    
    @IBOutlet weak var searchSongTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    let songCellIdentifier = "SongCell"
    @IBOutlet weak var tagView: UIView!
    @IBOutlet weak var tagViewSongImageView: UIImageView!
    @IBOutlet weak var tagViewSongLabel: UILabel!
    @IBOutlet weak var tagViewArtistLabel: UILabel!
    @IBOutlet weak var addTagTextField: UITextField!
    @IBOutlet weak var collectionView: CollectionView!
    let tagCellReuseIdentifier = "TagReuseCell"
    let slideAnimationDuration = 0.25
    
    @IBOutlet weak var tagViewSlideUpConstraint: NSLayoutConstraint!
    @IBOutlet weak var tagViewSlideDownConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var playingSong: UILabel!
    
    var currentSelectedSong: Song = Song(trackId: "") {
        didSet {
            tagViewSongLabel.text = currentSelectedSong.name
            tagViewArtistLabel.text = currentSelectedSong.artist
            let firstFourLetters = currentSelectedSong.imageSource.index(currentSelectedSong.imageSource.startIndex, offsetBy:4)
            if currentSelectedSong.imageSource.substring(to: firstFourLetters) == "http" {
                let url = URL(string: currentSelectedSong.imageSource)
                let data = try? Data(contentsOf: url!)
                tagViewSongImageView.image = UIImage(data: data!)
            } else {
                tagViewSongImageView.image = UIImage(named: currentSelectedSong.imageSource)
            }
        }
    }
    let allSongNames: [String] = [
        "Bruno Mars - That's What I Like",
        "Ed Sheeran - Shape of You",
        "Magic! - Rude",
        "Bruno Mars - 24K Magic",
        "Maroon 5 - Don't Wanna Know",
        "Ariana Grande - Into You",
        "The Weeknd - The Hills",
        "Taylor Swift - Wildest Dreams",
        "Mark Ronson - Uptown Funk ft. Bruno Mars"
    ]
    let allSongTrackIds: [String] = [
        "1161504043",
        "1193701392",
        "881629103",
        "1161504024",
        "1163339802",
        "1101917079",
        "1017804205",
        "907242710",
        "1011384691"
    ]
    var currentUserSongList = [Song]()
    var followingSongList = [Song]() // including only ones currently checked
    var userAllSongList = [Song]()
    var searchedSongList = [Song]()
//    var userAllSongDict = [String: Song]()
    var userFollowingSongDict = [String: Song]()
    var followingUserTagSongDict = [String: [String: Set<Song>]]()
    
    var searchString = ""
    var searchLimit = 25
    var isSearching = false
  
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
        
        //initializeDefaultAllSongList()
        //searchedSongList = currentUserSongList
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.delegate = self
        view.addGestureRecognizer(tap)  // Allows dismissal of keyboard on tap anywhere on screen besides the keyboard itself
        //set collectionViewCell to autoresize
        if let cvl = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            cvl.estimatedItemSize = CGSize(width: 60, height: 30)
        }
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else { print("no user!"); return }
            print("welcome \(user.email!) for logging in")
            self.appDelegate.currentUser = TagifyUser(authData: user)
            self.updateCurrentUserSongList()
//            self.initializeFollowingForCurrentUser()
            let followingRef = self.userProfilesRef.child("\(self.appDelegate.currentUser.uid)/following")
            followingRef.observe(.value, with: { snapshot in
                self.updateFollowingSongList(withFollowingSnapshot: snapshot)
            })
        }
        appleMusicFetchStorefrontRegion()
        requestAppleMusicAuthorization()
        
        activateBackGroundPlay()
    }
    override func viewWillAppear(_ animated: Bool) { // suggest sign up and check capability
        if authorizationStatus == true && !self.didCheckAndSuggestAppleMusicSignUp {
            self.checkAndSuggestAppleMusicSignUp()
            self.didCheckAndSuggestAppleMusicSignUp = true
        }
        let controller = SKCloudServiceController()
        controller.requestCapabilities(completionHandler: ({ (capabilities, error) in
            if let error = error {
                print("Error requesting Apple Music Capability: \(error.localizedDescription)")
            } else {
                switch capabilities {
                case SKCloudServiceCapability.addToCloudMusicLibrary: self.appleMusicCapable = true
                case SKCloudServiceCapability.musicCatalogPlayback: self.appleMusicCapable = true
                default: self.appleMusicCapable = false
                }
            }
        }))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
    @IBAction func searchSongEditDidEnd(_ sender: UITextField) {
        searchLimit = 25
        nowPlayingIndex = -1
        if let search = sender.text {
            self.searchString = search
            self.searchAndDisplay(withSearchString: search)
        }
        print("End Editing! Start Searching")
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        closeTagView()
        addTagTextField.text = ""
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
        showTagView()
    }
    
    @IBAction func addTagButtonPressed(_ sender: Any) {
        addTagTextField.resignFirstResponder()
        if let text = addTagTextField.text {
            addTag(text: text)
        }
        addTagTextField.text = ""
    }
    
    @IBAction func playButtonPressed(_ sender: Any) {
        if applicationMusicPlayer.nowPlayingItem != nil || self.player.isPlaying {
            pausePlay()
            playButton.setImage(UIImage(named: "playButton.png"), for: .normal)
        } else {
            if nowPlayingIndex == -1 {
                let firstSong = searchedSongList[0]
                if self.appleMusicCapable {
                    appleMusicPlayTrackId(trackId: firstSong.trackId)
                    print("Playing: \(firstSong.name)")
                    print("TrackId: \(firstSong.trackId)")
                } else {
                    playSampleMusic(withURLString: firstSong.previewURL)
                }
                self.playingSong.text = "\(firstSong.artist) - \(firstSong.name)"
            }
            nowPlayingIndex = 0
            continuePlay()
            playButton.setImage(UIImage(named: "stopButton.png"), for: .normal)
        }
    }
    @IBAction func forwardButtonPressed(_ sender: Any) {
        playNext()
        playButton.setImage(UIImage(named: "stopButton.png"), for: .normal)
    }
    @IBAction func backwardButtonPressed(_ sender: Any) {
        playPrevious()
        playButton.setImage(UIImage(named: "stopButton.png"), for: .normal)
    }
    @IBAction func shuffleButtonPressed(_ sender: Any) {
        shuffle()
    }
    @IBAction func loopButtonPressed(_ sender: Any) {
        loop()
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
        tableView.deselectRow(at: indexPath, animated: true)
        if let cell = tableView.cellForRow(at: indexPath) as? SongTableViewCell {
            if self.appleMusicCapable {
                songClicked(song: cell.song, index: indexPath.row)
            } else {
                playSampleMusic(withURLString: cell.song.previewURL)
            }
            nowPlayingIndex = indexPath.row
            self.playingSong.text = "\(cell.song.artist) - \(cell.song.name)"
            playButton.setImage(UIImage(named: "stopButton.png"), for: .normal)
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100;
    }
}

extension SongViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isSearching {
            let offset = scrollView.contentOffset
            let bounds = scrollView.bounds
            let size = scrollView.contentSize
            let inset = scrollView.contentInset
            let y = Float(offset.y + bounds.size.height - inset.bottom)
            let h = Float(size.height)
            let reload_distance: Float = 50;
            if y > (h + reload_distance) {
                DispatchQueue.main.async {
                    scrollView.bounces = true
                    self.loadMore()
                    scrollView.isScrollEnabled = false
                    UIView.animate(withDuration:0.5, animations: {
                        scrollView.setContentOffset(offset, animated: true)
                        scrollView.isScrollEnabled = true
                    })
                    //scrollViewDidEndDragging(scrollView, willDecelerate: true)
                    print("loading \(self.searchLimit) items")
                }
            }
        }
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
        //cell.layer.borderWidth = 2
        if let newCell = cell as? CollectionViewCell {
            let tags = currentSelectedSong.tags
            newCell.tagLabel.text = "#"+tags[tags.index(tags.startIndex, offsetBy: indexPath.row)]
        }
        return cell
    }
    func addTag(text: String) {
        if text != "" {
            let (valid, errorMessage) = isValid(tag: text)
            if valid {
                // To Do: Handle tags from multiple users
                let strippedTag = text.substring(from: text.index(text.startIndex, offsetBy: 1))
                currentSelectedSong.tags.insert(strippedTag)
                appDelegate.currentUser.add(tag: strippedTag, forSong: currentSelectedSong)
                // To Do: Handle hashtags from multiple users
                updateCollectionView()
            } else {
                let alert = UIAlertController(title: "Invalid Tag", message: errorMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
        }
    }
    func removeTag() {
        if let tagToRemove = collectionView.currentSelectedCell.tagLabel.text {
            // To Do: Handle hashtags from multiple users
            let strippedTag = tagToRemove.substring(from: tagToRemove.index(tagToRemove.startIndex, offsetBy: 1))
            self.currentSelectedSong.tags.remove(strippedTag)
            self.appDelegate.currentUser.remove(tag: strippedTag, forSong: self.currentSelectedSong)
            // To Do: Handle hashtags from multiple users
            updateCollectionView()
        }
    }
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if collectionView.isFirstResponder {
            switch  action {
            case #selector(self.removeTag), #selector(self.searchSongsWithSelectedTag):
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
    func isValid(tag: String) -> (Bool, String) {
        guard tag != "" else { return (false, "Tag should not be empty") }
        guard tag.characters.first == "#" else { return (false, "Tag should start with #") }
        guard tag[tag.index(before: tag.endIndex)] != " " else { return (false, "Tag should not end with space") }
        guard !tag.substring(from: tag.index(tag.startIndex, offsetBy: 1)).contains("#") else { return (false, "Tag should not contain # besides the first one") }
        guard !tag.contains("&") else { return (false, "Tag should not contain &") }
        return (true, "")
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
        self.tableView.reloadData()
    }
    func showTagView() {
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
    func searchSongsWithSelectedTag() { // search with selected tag in tag view
        let searchString = collectionView.currentSelectedCell.tagLabel.text!
        searchedSongList = searchedSongs(fromSongSet: Set(userAllSongList), withHashTagString: searchString)
        tableView.reloadData()
        searchSongTextField.text = searchString
        closeTagView()
        print("search songs with tag \(collectionView.currentSelectedCell.tagLabel.text!)")
    }
}

extension SongViewController { // related to search
    func searchedSongs(fromSongSet songSet: Set<Song>, withHashTagString hashTagString: String) -> [Song] {
        if hashTagString == "" {
            return Array(songSet)
        }
        var result = [Song]()
        let union = hashTagString.components(separatedBy: "&")
        for hashTagSubstring in union {
            var intersection = hashTagSubstring.components(separatedBy: "#")
            intersection.remove(at: 0)
            // append # in front and remove trailing spaces
            intersection = intersection.map {"\($0)".replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)}
            for song in songSet {
                if song.tags.union(intersection).count == song.tags.count {
                    result.append(song)
                }
            }
        }
        return result
    }
}

extension SongViewController { // Initialize a default song list, to be replaced by top hits
    func initializeDefaultAllSongList() {
        currentUserSongList = []
        for (index, song) in allSongNames.enumerated() {
            let artist_songname = song.components(separatedBy: " - ")
            let songname = artist_songname[1]
            let artist = artist_songname[0]
            var imageSource = "music.jpg"
            if song.range(of: "Bruno Mars") != nil {
                imageSource = "BrunoMars.jpg"
            } else if song.range(of: "Magic!") != nil {
                imageSource = "Magic!.png"
            } else if song.range(of: "Taylor Swift") != nil {
                imageSource = "TaylorSwift.jpg"
            } else if song.range(of: "Maroon 5") != nil {
                imageSource = "Maroon5.jpg"
            }
            let newSong = Song(name: songname, artist: artist, trackId: allSongTrackIds[index], imageSource: imageSource, previewURL: "")
            newSong.tags = ["Pop", "Wedding", "Shower", "Mona Lisa"]
            currentUserSongList.append(newSong)
        }
    }
    func updateFollowingSongList(withFollowingSnapshot snapshot: DataSnapshot) {
        userFollowingSongDict = [String: Song]()
        for childSnapshot in snapshot.children.allObjects {
            let childSnapshot = childSnapshot as! DataSnapshot
            let listenedTo = childSnapshot.value as? Bool ?? false
            guard listenedTo == true else { continue } // checking listening to
            let followingUserUID = childSnapshot.key
            let followingUserSongsRef = userSongsRef.child("\(followingUserUID)/songs")
            followingUserSongsRef.observe( .value, with: { snapshot in
                for songSnap in snapshot.children.allObjects {
                    let songSnap = songSnap as! DataSnapshot
                    let song = Song(snapshot: songSnap)
                    if let storedSong = self.userFollowingSongDict[song.trackId] {
                        storedSong.tags.formUnion(song.tags)
                    } else {
                        self.userFollowingSongDict[song.trackId] = song
                    }
                }
                self.updateSongList()
            })
        }
    }
    func updateCurrentUserSongList() { // Taking care of new user who has no initial
        let currentUserSongsRef = self.userSongsRef.child("\(appDelegate.currentUser.uid)/songs")
        currentUserSongsRef.observe(.value, with: { (snapshot) in
            if snapshot.exists() {
                self.appDelegate.currentUser.updateSongs(songsSnapshot: snapshot)
                self.currentUserSongList = Array(self.appDelegate.currentUser.songs)
                //self.searchedSongList = self.currentUserSongList
            } else {
//                for song in self.currentUserSongList {
//                    currentUserSongsRef.child("\(song.trackId)").setValue(song.toAnyObject())
//                }
//                self.appDelegate.currentUser.songs = Set(self.currentUserSongList) // To Do: Potential problem with copy by reference
            }
            self.updateSongList()
        })
        let currentUserListeningToSelfRef = self.userProfilesRef.child("\(appDelegate.currentUser.uid)/listeningToSelf")
        currentUserListeningToSelfRef.observe(.value, with: { snapshot in
            self.appDelegate.currentUser.updateListeningToSelf(listeningToSelfSnapshot: snapshot)
            print("I'm currently listening to self: \(self.appDelegate.currentUser.listeningToSelf)")
            self.updateSongList()
        })
    }
    func updateSongList() {
        var newAllSongDict = userFollowingSongDict
        if appDelegate.currentUser.listeningToSelf {
            for song in self.currentUserSongList {
                if let storedSong = newAllSongDict[song.trackId] {
                    storedSong.tags.formUnion(song.tags)
                } else {
                    newAllSongDict[song.trackId] = song
                }
            }
        }
        self.userAllSongList = newAllSongDict.map { $1 }
        searchAndDisplay(withSearchString: searchSongTextField.text!)
    }
    func searchAndDisplay(withSearchString search: String) {
        if searchString == "" {
            isSearching = false
            searchedSongList = userAllSongList
            tableView.reloadData()
        } else if searchString[searchString.startIndex] == "#" {
            searchedSongList = searchedSongs(fromSongSet: Set(userAllSongList), withHashTagString: searchString)
            tableView.reloadData()
        } else {
            tableView.setContentOffset(CGPoint.zero, animated: true)
            isSearching = true
            searchItunes(searchTerm: searchString, limit: searchLimit) { list in
                self.searchedSongList = list
                self.tableView.reloadData()
            }
        }
        print(self.searchedSongList)
    }
}

extension SongViewController { //Related to Music
    
    func requestMPMediaLibraryAccessAgain() {
        let authorizationStatus = MPMediaLibrary.authorizationStatus()
        switch authorizationStatus {
        case .denied:
            print("media library access denied, we are going to request it again")
            presentMediaLibraryAccessAlert()
        case .authorized:
            print("good, we have access to media library")
        case .restricted:
            print("no media library access, restricted device, education mode?")
        case .notDetermined:
            print("media library access not determined yet. I should not see this string")
        }
    }
    
//****************** RequestAppleMusicAuthorization **********************//
    func requestAppleMusicAuthorization() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        //Ask user for for Apple Music access
        let authorizationStatus = SKCloudServiceController.authorizationStatus()
        switch authorizationStatus {
        case .notDetermined:
            AppleMusicAuthorizationForTheFirstTime()
        case .authorized:
            self.authorizationStatus = true
            if !self.didCheckAndSuggestAppleMusicSignUp {
                self.checkAndSuggestAppleMusicSignUp()
                self.didCheckAndSuggestAppleMusicSignUp = true
            }
        case .denied:
            self.authorizationStatus = false
            if !self.didAskForMediaLibraryAccess {
                presentMediaLibraryAccessAlert()
                self.didAskForMediaLibraryAccess = true
            }
            print("User has denied access to Apple Music library")
        case .restricted:
            self.authorizationStatus = false
            print("user's device has restricted access, maybe education mode")
        }
    }
    func AppleMusicAuthorizationForTheFirstTime() {
        SKCloudServiceController.requestAuthorization { (status) in
            switch status {
            case .authorized:
                self.authorizationStatus = true
                if !self.didCheckAndSuggestAppleMusicSignUp {
                    self.checkAndSuggestAppleMusicSignUp()
                    self.didCheckAndSuggestAppleMusicSignUp = true
                }
            case .denied:
                self.authorizationStatus = false
                print("User has denied access to Apple Music library")
            case .restricted:
                self.authorizationStatus = false
                print("User's device has restricted access, maybe education mode")
            case .notDetermined:
                self.authorizationStatus = false
                print("Apple Music Access not determined, should not see this message")
            }
        }
    }
    func checkAndSuggestAppleMusicSignUp() {
        let controller = SKCloudServiceController()
        controller.requestCapabilities(completionHandler: ({ (capabilities, error) in
            if let error = error {
                print("Error requesting Apple Music Capability: \(error.localizedDescription)")
                DispatchQueue.main.async(execute: {
                    //self.showAlert("Capabilites error", error: "You must be an Apple Music member to use this application")
                    print("You must be an Apple Music member to use this application")
                })
            } else {
                switch capabilities {
                case SKCloudServiceCapability.addToCloudMusicLibrary:
                    self.appleMusicCapable = true
                    print("has addToCloudMusicLibrary capability")
                case SKCloudServiceCapability.musicCatalogPlayback:
                    self.appleMusicCapable = true
                    print("has addToCloudMusicLibrary capability")
                default:
                    self.appleMusicCapable = false
                    print("No Apple Music Memebership, we will suggest signing up")
                    self.presentAppleMusicSignUpAlert()
                }
            }
        }))
    }
    func presentAppleMusicSignUpAlert() { // helper function to present Apple Music Sign Up alert
        let alertController = UIAlertController(title: "Would You Like to Sign Up For Apple Music", message: "...to play full songs", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Sign Up", style: .default, handler: { (action) in
            if let url = URL(string: "https://www.apple.com/apple-music/membership/") {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        })
        let cancelAction = UIAlertAction(title: "Maybe Later", style: .default, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        alertController.preferredAction = confirmAction
        while self.presentedViewController != nil { }
        self.present(alertController, animated: true, completion: nil)
    }
    func presentMediaLibraryAccessAlert() {
        let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        let titleString = "\"\(appName)\" Would Like to Access Apple Music And Your Media Library"
        let alertController = UIAlertController(title: titleString, message: "...to play full songs", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
            let url = URL(string: UIApplicationOpenSettingsURLString)
            UIApplication.shared.open(url!)
        })
        let cancelAction = UIAlertAction(title: "Don't Allow", style: .default, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        alertController.preferredAction = confirmAction
        self.present(alertController, animated: true, completion: nil)
    }
//**********************************************************************//
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
            self.storefrontId = trimmedId
            return
        })
    }
    // Choose Player type & Play
    func appleMusicPlayTrackId(trackId: String) {
        applicationMusicPlayer.setQueueWithStoreIDs([trackId])
        applicationMusicPlayer.prepareToPlay()
        applicationMusicPlayer.play()
        playButton.setImage(UIImage(named: "stopButton.png"), for: .normal)
    }
    func activateBackGroundPlay() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            print("AVAudioSession Category Playback OK")
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                print("AVAudioSession is Active")
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
    }
    func playSampleMusic(withURLString urlString: String) {
        if let url = URL(string: urlString) {
            let playerItem = AVPlayerItem(url: url)
            self.player = AVPlayer(playerItem:playerItem)
            self.player!.volume = 1.0
            self.player!.play()
        } else {
            print("invalid url string for sample music")
        }
    }
    //Control playback
    func pausePlay() {
        if self.appleMusicCapable {
            applicationMusicPlayer.pause()
        } else if (self.player != nil) {
            self.player.pause()
        }
        print("Music paused")
    }
    func continuePlay() {
        if self.appleMusicCapable {
            applicationMusicPlayer.play()
        } else if (self.player != nil) {
            self.player.play()
        }
        print("Music continued")
    }
    func playNext() {
        print("Play next song")
        //applicationMusicPlayer.skipToNextItem()
        if nowPlayingIndex < searchedSongList.count-1 {
            nowPlayingIndex += 1
        } else {
            nowPlayingIndex = 0
        }
        let nextSong = searchedSongList[nowPlayingIndex]
        if self.appleMusicCapable {
            let nextTrack = nextSong.trackId
            applicationMusicPlayer.setQueueWithStoreIDs([nextTrack])
            applicationMusicPlayer.prepareToPlay()
            applicationMusicPlayer.play()
        } else {
            playSampleMusic(withURLString: nextSong.previewURL)
        }
        self.playingSong.text = "\(nextSong.artist) - \(nextSong.name)"
        print("Playing: \(nextSong.name)")
    }
    func playPrevious() {
        print("Play previous song")
        //applicationMusicPlayer.skipToPreviousItem()
        if nowPlayingIndex > 1 {
            nowPlayingIndex -= 1
        } else {
            nowPlayingIndex = searchedSongList.count-1
        }
        let prevSong = searchedSongList[nowPlayingIndex]
        if self.appleMusicCapable {
            let prevTrack = prevSong.trackId
            applicationMusicPlayer.setQueueWithStoreIDs([prevTrack])
            applicationMusicPlayer.prepareToPlay()
            applicationMusicPlayer.play()
        } else {
            playSampleMusic(withURLString: prevSong.previewURL)
        }
        self.playingSong.text = "\(prevSong.artist) - \(prevSong.name)"
        print("Playing: \(prevSong.name)")
    }
    func shuffle() {
        print("shuffle")
        let shuffleMode = applicationMusicPlayer.shuffleMode
        switch shuffleMode {
        case .off:
            applicationMusicPlayer.shuffleMode = MPMusicShuffleMode.songs
        case .songs:
            applicationMusicPlayer.shuffleMode = MPMusicShuffleMode.off
        case .albums:
            applicationMusicPlayer.shuffleMode = MPMusicShuffleMode.off
        default:
            applicationMusicPlayer.shuffleMode = MPMusicShuffleMode.songs
        }
    }
    func loop() {
        print("loop")
        let repeatMode = applicationMusicPlayer.repeatMode
        switch repeatMode {
        case .none:
            applicationMusicPlayer.repeatMode = MPMusicRepeatMode.all
        case .all:
            applicationMusicPlayer.repeatMode = MPMusicRepeatMode.one
        case .one:
            applicationMusicPlayer.repeatMode = MPMusicRepeatMode.none
        default:
            applicationMusicPlayer.repeatMode = MPMusicRepeatMode.all
        }
    }
    //Search iTunes and display results in table view
    func removeSpecialChars(str: String) -> String {
        var allowedCharacters = NSCharacterSet.urlQueryAllowed //.mutableCopy() as NSMutableCharacterSet
        allowedCharacters.remove(charactersIn: "+/=")
        return str.addingPercentEncoding(withAllowedCharacters: allowedCharacters)!
    }
    func searchItunes(searchTerm: String, limit: Int, callback: @escaping ([Song]) ->() ) {
        var songList = [Song]()
        let search = removeSpecialChars(str: searchTerm).replacingOccurrences(of: " ", with: "+")
        Alamofire.request("https://itunes.apple.com/search?term=\(search)&entity=song&limit=\(limit)&s=\(self.storefrontId)")
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success:
                    if let responseData = response.result.value as? NSDictionary {
                        if let resultCount = responseData.value(forKey: "resultCount") as? Int {
                            if resultCount == 0 {
                                print("No result found.")
                            } else if let songResults = responseData.value(forKey: "results") as? [NSDictionary] {
                                for result in songResults {
                                    let singer = result["artistName"] as! String
                                    let songName = result["trackName"] as! String
                                    let trackNum = result["trackId"] as! NSNumber
                                    let track = "\(trackNum)"
                                    let imageUrl = result["artworkUrl100"] as! String
                                    let previewURL = result["previewUrl"] as? String ?? ""
                                    let song = Song(name: "\(songName)", artist: singer, trackId: track, imageSource: imageUrl, previewURL: previewURL)
                                    songList.append(song)
                                }
                            }
                            callback(songList)
                        }
                    }
                case .failure(let error):
                    //self.showAlert("Error", error: error.description)
                    print("Failed to search itunes.")
                }
        }
    }
    func loadMore() {
        searchItunes(searchTerm: searchString, limit: searchLimit) { list in
            if list.count > 0 {
                if list.count > self.searchedSongList.count {
                    self.searchLimit += 5
                    self.searchedSongList = list
                    self.tableView.reloadData()
                } else {
                    self.searchLimit = list.count
                }
            }
        }
    }
    func songClicked(song: Song, index: Int) {
        appleMusicPlayTrackId(trackId: song.trackId)
        print("Playing: \(song.name)")
        print("TrackId: \(song.trackId)")
    }
//**********************************************************************//
    //Update playlist
    func updatePlaylist(index: Int) {
        
    }
    
    /*
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

}

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}
