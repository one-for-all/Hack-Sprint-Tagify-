//
//  FollowingViewController.swift
//  Tagify
//
//  Created by Camille Zhang on 5/26/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import UIKit

class FollowedUser {
    let uid: String
    var username: String = ""
    var userIcon: UIImage = UIImage()
    init(uid: String) {
        self.uid = uid
    }
}

class FollowerViewController: UIViewController, UITextFieldDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let storageRef: StorageReference! = Storage.storage().reference()
    let userProfilesRef = Database.database().reference(withPath: "userProfiles")
    var follower = [TagifyUserForDisplay]()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let currentUserFollowingRef = userProfilesRef.child("\(appDelegate.currentUser.uid)/followedBy")
        currentUserFollowingRef.observe(.value, with: { snapshot in
            self.updateTableView(withFollowerSnapshot: snapshot)
            self.appDelegate.currentUser.updateFollowers(followerSnapshot: snapshot)
        })
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
        let searchString = sender.text!.lowercased()
        //print(searchString)
        follower = [TagifyUserForDisplay]()
        let currentUserFollowerRef = userProfilesRef.child("\(appDelegate.currentUser.uid)/followedBy")
        currentUserFollowerRef.observeSingleEvent(of: .value, with: { snapshot in
            for childSnapshot in snapshot.children.allObjects {
                let childSnapshot = childSnapshot as! DataSnapshot
                let followerUID = childSnapshot.key
                let followerRef = self.userProfilesRef.child(followerUID)
                followerRef.observeSingleEvent(of: .value, with: { snapshot in
                    let userName = snapshot.childSnapshot(forPath: "username").value as? String ?? ""
                    if (userName.lowercased().contains(searchString) || searchString == "") {
                        //print ("searched!!!")
                        let followerUser = TagifyUserForDisplay(userSnapshot: snapshot, completion: {
                            self.tableView.reloadData()
                        })
                        self.follower.append(followerUser)
                    }
                })
            }
            self.tableView.reloadData()
        })
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

extension FollowerViewController {
    func updateTableView(withFollowerSnapshot snapshot: DataSnapshot) {
        follower = [TagifyUserForDisplay]()
        for childSnapshot in snapshot.children.allObjects {
            let childSnapshot = childSnapshot as! DataSnapshot
            let followerUserUID = childSnapshot.key
            let followerUserRef = userProfilesRef.child(followerUserUID)
            followerUserRef.observeSingleEvent(of: .value, with: { snapshot in
                let followerUser = TagifyUserForDisplay(userSnapshot: snapshot, completion: {
                    self.tableView.reloadData()
                })
                self.follower.append(followerUser)
            })
        }
    }
}

extension FollowerViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.follower.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FollowerCell") as! FollowerTableViewCell
        cell.usernameLabel.text = self.follower[indexPath.row].username
        cell.userIconImageView.image = self.follower[indexPath.row].userIcon
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}
