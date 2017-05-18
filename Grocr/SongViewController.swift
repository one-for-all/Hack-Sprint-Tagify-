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
    
    @IBAction func searchSongEditDidEnd(_ sender: UITextField) {
        print("End Editing!")
        var newSongList: [String] = []
        if let searchString = sender.text {
            if searchString == "" {
                songListTableView.songList = songList
            } else {
                for song in songList {
                    if song.range(of:searchString) != nil{
                        newSongList.append(song)
                    }
                }
                songListTableView.songList = newSongList
            }
        }
        songListTableView.tableView.reloadData()
    }

    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
        print("Pressed Return!")
        textField.resignFirstResponder()
        return true
    }
  
  let songList: [String] = [
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
    var songListTableView: SongTableViewController!
  
  

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.dataSource = self
        tableView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let destination = segue.destination as! SongTableViewController
        songListTableView = destination
        destination.songList = self.songList
    }
    
    @IBAction func logOffPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

}

extension SongViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songList.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: songCellIdentifier, for: indexPath)
        cell.textLabel?.text = songList[indexPath.row]
        return cell
    }
}
