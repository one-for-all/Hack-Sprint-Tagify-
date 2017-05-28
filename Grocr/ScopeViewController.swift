//
//  ScopeViewController.swift
//  Tagify
//
//  Created by 迦南 on 5/24/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import UIKit

class ScopeViewController: UIViewController {
    
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
                            self.tableView.reloadData()
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

extension ScopeViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.following.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScopeCell") as! ScopeTableViewCell
        cell.usernameLabel.text = self.following[indexPath.row].username
        cell.iconImageView.image = self.following[indexPath.row].userIcon
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
}
