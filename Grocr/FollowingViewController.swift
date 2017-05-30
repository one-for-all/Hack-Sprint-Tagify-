//
//  FollowingViewController.swift
//  Tagify
//
//  Created by Camille Zhang on 5/26/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import UIKit

class FollowingViewController: UIViewController, UITextFieldDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let storageRef: StorageReference! = Storage.storage().reference()
    let userProfilesRef = Database.database().reference(withPath: "userProfiles")
    var following = [TagifyUserForDisplay]()
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let currentUserFollowingRef = userProfilesRef.child("\(appDelegate.currentUser.uid)/following")
        currentUserFollowingRef.observe(.value, with: { snapshot in
            self.updateTableView(withFollowingSnapshot: snapshot)
            self.appDelegate.currentUser.updateFollowing(followingSnapshot: snapshot)
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
        following = [TagifyUserForDisplay]()
        let currentUserFollowingRef = userProfilesRef.child("\(appDelegate.currentUser.uid)/following")
        currentUserFollowingRef.observeSingleEvent(of: .value, with: { snapshot in
            for childSnapshot in snapshot.children.allObjects {
                let childSnapshot = childSnapshot as! DataSnapshot
                let followingUID = childSnapshot.key
                let followingRef = self.userProfilesRef.child(followingUID)
                followingRef.observeSingleEvent(of: .value, with: { snapshot in
                    var userName = snapshot.childSnapshot(forPath: "username").value as? String ?? ""
                    userName = userName.lowercased()
                    if (userName.contains(searchString) || searchString == "") {
                        //print ("searched!!!")
                        let followingUser = TagifyUserForDisplay(userSnapshot: snapshot, completion: {
                            self.tableView.reloadData()
                        })
                        self.following.append(followingUser)
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
extension FollowingViewController {
    func updateTableView(withFollowingSnapshot snapshot: DataSnapshot) {
        following = [TagifyUserForDisplay]()
        for childSnapshot in snapshot.children.allObjects {
            let childSnapshot = childSnapshot as! DataSnapshot
            let followingUserUID = childSnapshot.key
            let followingUserRef = userProfilesRef.child(followingUserUID)
            followingUserRef.observeSingleEvent(of: .value, with: { snapshot in
                let followingUser = TagifyUserForDisplay(userSnapshot: snapshot, completion: {
                    self.tableView.reloadData()
                })
                self.following.append(followingUser)
            })
        }
    }
}

extension FollowingViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.following.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FollowingCell") as! FollowingTableViewCell
        if indexPath.row < self.following.count {
            cell.usernameLabel.text = self.following[indexPath.row].username
            cell.userIconImageView.image = self.following[indexPath.row].userIcon
        }
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if indexPath.row < self.following.count {
                let userToUnfollow = self.following[indexPath.row]
                self.following.remove(at: indexPath.row)
                self.tableView.reloadData()
                appDelegate.currentUser.unfollow(uid: userToUnfollow.uid)
            }
        }
    }
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Unfollow"
    }
}
