//
//  FollowingViewController.swift
//  Tagify
//
//  Created by Camille Zhang on 5/26/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import UIKit

class FollowingUser {
    let uid: String
    var username: String = ""
    var userIcon: UIImage = UIImage()
    init(uid: String) {
        self.uid = uid
    }
}

class FollowingViewController: UIViewController {
    
    var currentUser: TagifyUser = TagifyUser(uid: "")
    var following = [FollowingUser]()
    let storageRef: StorageReference! = Storage.storage().reference()
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.currentUser = appDelegate.currentUser
        let userFollowingRef = Database.database().reference().child("userProfiles/\(self.currentUser.uid)/following")
        userFollowingRef.observe(.value, with: { snapshot in
            self.currentUser.updateFollowing(followingSnapshot: snapshot)
            for uid in self.currentUser.following {
                let followingUserNameRef = Database.database().reference().child("userProfiles/\(uid)")
                var followingUser = FollowingUser(uid: uid)
                let index = self.following.count
                self.following.append(followingUser)
                followingUserNameRef.observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists() {
                        let username = snapshot.childSnapshot(forPath: "username").value as! String
                        print("this user is \(username)")
                        self.following[index].username = username
                        let userIconPath = "\(uid)/userIcon.jpg"
                        let reference = self.storageRef.child(userIconPath)
                        reference.getData(maxSize: 1 * 1024 * 1024) { data, error in
                            if let error = error {
                                print(error.localizedDescription)
                                self.following[index].userIcon = UIImage(named: "music.jpg")!
                            } else {
                                print("got image")
                                self.following[index].userIcon = UIImage(data: data!)!
                            }
                            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                        }
                    }
                })
            }
        })
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

extension FollowingViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.following.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FollowingCell") as! FollowingTableViewCell
        cell.usernameLabel.text = self.following[indexPath.row].username
        cell.userIconImageView.image = self.following[indexPath.row].userIcon
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
        }
    }
}
