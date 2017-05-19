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
                for song in allSongNames {
                    if song.range(of:searchString) != nil{
                        newSongList.append(Song(name: song))
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
        for song in allSongNames {
            allSongList.append(Song(name: song))
        }
        searchedSongList = allSongList
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
        cell.songNameLabel.text = searchedSongList[indexPath.row].name
        return cell
    }
}
