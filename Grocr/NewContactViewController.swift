//
//  NewContactViewController.swift
//  Tagify
//
//  Created by 迦南 on 5/27/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import UIKit

class TagifyUserMinimal {
    let uid: String
    var username: String = ""
    var userIcon: UIImage = UIImage()
    init(uid: String) {
        self.uid = uid
    }
}

class NewContactViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    var searchedUser = [TagifyUserMinimal]()
    var currentUser: TagifyUser!
    
    let storageRef: StorageReference! = Storage.storage().reference()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        searchTextField.returnKeyType = .search
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.currentUser = appDelegate.currentUser
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
        print("Pressed Return!")
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func searchTextFieldEditingDidEnd(_ sender: UITextField) {
        let searchedUsername = sender.text!
        let ref = Database.database().reference().child("userProfiles")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            self.searchedUser = [TagifyUserMinimal]()
            for childSnapshot in snapshot.children {
                let childSnapshot = childSnapshot as! DataSnapshot
                let usernameSnapshot = childSnapshot.childSnapshot(forPath: "username")
                if usernameSnapshot.exists() {
                    let username = usernameSnapshot.value as! String
                    let followedByCurrentUserSnap = childSnapshot.childSnapshot(forPath: "followedBy/\(self.currentUser.uid)")
                    if username.contains(searchedUsername) && !followedByCurrentUserSnap.exists() {
                        let userIconPath = "\(childSnapshot.key)/userIcon.jpg"
                        let reference = self.storageRef.child(userIconPath)
                        reference.getData(maxSize: 1 * 1024 * 1024) { data, error in
                            let user = TagifyUserMinimal(uid: childSnapshot.key)
                            user.username = username
                            let index = self.searchedUser.count
                            self.searchedUser.append(user)
                            if let error = error {
                                print(error.localizedDescription)
                                self.searchedUser[index].userIcon = UIImage(named: "music.jpg")!
                            } else {
                                print("got image")
                                self.searchedUser[index].userIcon = UIImage(data: data!)!
                            }
                            self.tableView.reloadData()
                            //self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                        }
                    }
                }
            }
        })
    }
    
    @IBAction func plusButtonTapped(_ sender: UIButton) {
        print(sender.tag)
        let cell = tableView.cellForRow(at: IndexPath(row: sender.tag, section: 0)) as! NewContactTableViewCell
        self.currentUser.follow(uid: cell.user.uid)
        print("cell number \(sender.tag) pressed, username: \(cell.usernameLabel.text)")
        sender.isHidden = true
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}

extension NewContactViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchedUser.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewContactCell", for: indexPath) as! NewContactTableViewCell
        cell.user = searchedUser[indexPath.row]
        cell.usernameLabel.text = searchedUser[indexPath.row].username
        cell.userIconImageView.image = searchedUser[indexPath.row].userIcon
        cell.plusButton.tag = indexPath.row
        return cell
    }
}
