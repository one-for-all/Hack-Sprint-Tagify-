//
//  ScopeViewController.swift
//  Tagify
//
//  Created by 迦南 on 5/24/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import UIKit

class ScopeViewController: UIViewController {
    
    let userProfilesRef: DatabaseReference! = Database.database().reference(withPath: "userProfiles")
    let storage = Storage.storage()
    let storageRef: StorageReference! = Storage.storage().reference()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var settingsTableViewController: SettingsTableViewController!
    
    var following = [TagifyUserForDisplay]()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var personalTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let currentUserFollowingRef = userProfilesRef.child("\(appDelegate.currentUser.uid)/following")
        currentUserFollowingRef.queryOrderedByValue().observe(.value, with: { snapshot in
            self.updateTableView(withFollowingSnapshot: snapshot)
            self.appDelegate.currentUser.updateFollowing(followingSnapshot: snapshot)
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
extension ScopeViewController {
    func updateTableView(withFollowingSnapshot snapshot: DataSnapshot) {
        following = [TagifyUserForDisplay]()
        for childSnapshot in snapshot.children.allObjects {
            let childSnapshot = childSnapshot as! DataSnapshot
            let followingUserUID = childSnapshot.key
            let followingUserRef = userProfilesRef.child(followingUserUID)
            let listenedTo = childSnapshot.value as? Bool ?? false
            print(childSnapshot)
            print("value of listened to is \(listenedTo)")
            followingUserRef.observeSingleEvent(of: .value, with: { snapshot in
                let followingUser = TagifyUserForDisplay(userSnapshot: snapshot, completion: {
                    self.tableView.reloadData()
                })
                followingUser.listenedTo = listenedTo
                self.following.insert(followingUser, at: 0)
            })
        }
    }
}

extension ScopeViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == personalTableView {
            return 1
        }
        return self.following.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == personalTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PersonalCell")
            return cell!
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScopeCell") as! ScopeTableViewCell
        cell.user = self.following[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == personalTableView {
            return 70
        }
        return 50
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == personalTableView {
            let cell = tableView.cellForRow(at: indexPath)
            let newVal = !(cell?.accessoryType == .checkmark)
            toggleCellCheckbox(cell!, listenedTo: newVal)
            return
        }
        if indexPath.row < self.following.count {
            let cell = tableView.cellForRow(at: indexPath) as! ScopeTableViewCell
            let newVal = !(cell.user.listenedTo)
            toggleCellCheckbox(cell, listenedTo: newVal)
            self.following[indexPath.row].listenedTo = newVal
            self.appDelegate.currentUser.listenTo(uid: cell.user.uid, newVal)
        }
    }
}

extension ScopeViewController {
    func toggleCellCheckbox(_ cell: UITableViewCell, listenedTo: Bool) {
        if listenedTo {
            cell.accessoryType = .checkmark
//            cell.textLabel?.textColor = UIColor.black
//            cell.detailTextLabel?.textColor = UIColor.black
        } else {
            cell.accessoryType = .none
//            cell.textLabel?.textColor = UIColor.gray
//            cell.detailTextLabel?.textColor = UIColor.gray
        }
    }
}
