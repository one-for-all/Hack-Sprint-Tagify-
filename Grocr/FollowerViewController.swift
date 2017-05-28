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

class FollowerViewController: UIViewController {
  
  var currentUser: TagifyUser = TagifyUser(uid: "")
  var follower = [FollowedUser]()
  let storageRef: StorageReference! = Storage.storage().reference()
  
  @IBOutlet weak var tableView: UITableView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    self.currentUser = appDelegate.currentUser
    let userFollowerRef = Database.database().reference().child("userProfiles/\(self.currentUser.uid)/followedBy")
    userFollowerRef.observe(.value, with: { snapshot in
      self.currentUser.updateFollowers(followerSnapshot: snapshot)
      for uid in self.currentUser.followedBy {
        let followedUserNameRef = Database.database().reference().child("userProfiles/\(uid)")
        let followedUser = FollowedUser(uid: uid)
        let index = self.follower.count
        self.follower.append(followedUser)
        followedUserNameRef.observeSingleEvent(of: .value, with: { snapshot in
          if snapshot.exists() {
            let username = snapshot.childSnapshot(forPath: "username").value as! String
            print("this user is \(username)")
            self.follower[index].username = username
            let userIconPath = "\(uid)/userIcon.jpg"
            let reference = self.storageRef.child(userIconPath)
            reference.getData(maxSize: 1 * 1024 * 1024) { data, error in
              if let error = error {
                print(error.localizedDescription)
                self.follower[index].userIcon = UIImage(named: "music.jpg")!
              } else {
                print("got image")
                self.follower[index].userIcon = UIImage(data: data!)!
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

extension FollowerViewController: UITableViewDataSource, UITableViewDelegate {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.follower.count
  }
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    print("Getting next cell, with indexPath: \(indexPath.row)")
    let cell = tableView.dequeueReusableCell(withIdentifier: "FollowerCell") as! FollowerTableViewCell
    print("This cell's user is \(cell.usernameLabel.text)")
    cell.usernameLabel.text = self.follower[indexPath.row].username
    cell.iconImageView.image = self.follower[indexPath.row].userIcon
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
