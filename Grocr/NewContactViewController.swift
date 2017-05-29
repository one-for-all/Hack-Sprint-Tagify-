//
//  NewContactViewController.swift
//  Tagify
//
//  Created by 迦南 on 5/27/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import UIKit

class NewContactViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let storageRef: StorageReference! = Storage.storage().reference()
    let userProfilesRef = Database.database().reference(withPath: "userProfiles")
    var matchedUsers = [TagifyUserForDisplay]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        searchTextField.returnKeyType = .search
        searchAndDisplay(withSearchString: "") // display all users
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
        let searchString = sender.text!
        searchAndDisplay(withSearchString: searchString)
    }
    
    @IBAction func plusButtonTapped(_ sender: UIButton) {
        let cell = tableView.cellForRow(at: IndexPath(row: sender.tag, section: 0)) as! NewContactTableViewCell
        appDelegate.currentUser.follow(uid: cell.user.uid)
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
extension NewContactViewController {
    func searchAndDisplay(withSearchString searchString: String) {
        self.matchedUsers.removeAll()
        userProfilesRef.observeSingleEvent(of: .value, with: { snapshot in
            for childSnap in snapshot.children.allObjects {
                let childSnap = childSnap as! DataSnapshot
                guard childSnap.key != self.appDelegate.currentUser.uid else { continue }
                guard self.isMatch(userSnap: childSnap, searchString: searchString) else { continue }
                guard !self.alreadyFollowed(userSnap: childSnap, currentUserUID: self.appDelegate.currentUser.uid) else { continue }
                let matchedUser = TagifyUserForDisplay(userSnapshot: childSnap, completion: {
                    self.tableView.reloadData()
                })
                self.matchedUsers.append(matchedUser)
            }
        })
    }
    func isMatch(userSnap snapshot: DataSnapshot, searchString: String) -> Bool {
        if searchString == "" { return true }
        let username = snapshot.childSnapshot(forPath: "username").value as? String ?? ""
        return username.lowercased().contains(searchString.lowercased())
    }
    func alreadyFollowed(userSnap snapshot: DataSnapshot, currentUserUID: String) -> Bool {
        let followedBySnap = snapshot.childSnapshot(forPath: "followedBy")
        guard followedBySnap.exists() else { return false }
        let followedByDict = followedBySnap.value as? [String: Bool] ?? [String: Bool]()
        return followedByDict[currentUserUID] != nil
    }
}

extension NewContactViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.matchedUsers.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewContactCell", for: indexPath) as! NewContactTableViewCell
        cell.user = matchedUsers[indexPath.row]
        cell.plusButton.tag = indexPath.row
        cell.plusButton.isHidden = false
        return cell
    }
}
