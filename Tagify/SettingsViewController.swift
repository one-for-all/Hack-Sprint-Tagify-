//
//  SettingsViewController.swift
//  Tagify
//
//  Created by 迦南 on 5/24/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import UIKit
import FirebaseStorage


class SettingsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var iconImageView: UIImageView!
    
    let userProfilesRef: DatabaseReference! = Database.database().reference(withPath: "userProfiles")
    let storage = Storage.storage()
    let storageRef: StorageReference! = Storage.storage().reference()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var settingsTableViewController: SettingsTableViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        iconImageView.layer.cornerRadius = iconImageView.frame.height/2
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.iconImageTapped(_:)))
        iconImageView.addGestureRecognizer(tapRecognizer)
        
        // initial value
        self.settingsTableViewController.usernameLabel.text = self.appDelegate.currentUser.username
        self.iconImageView.image = self.appDelegate.currentUser.iconImage
        // Download User Profile image
        let userIconPath = "\(appDelegate.currentUser.uid)/userIcon.jpg"
        let reference = storageRef.child(userIconPath)
        reference.getData(maxSize: 1 * 1024 * 1024) { data, error in
            self.appDelegate.currentUser.updateIcon(data: data, error: error)
            self.iconImageView.image = self.appDelegate.currentUser.iconImage
        }
        let usernameRef = userProfilesRef.child("\(appDelegate.currentUser.uid)/username")
        usernameRef.observe(.value, with: { snapshot in
            self.settingsTableViewController.usernameLabel.text = snapshot.value as? String ?? ""
            self.appDelegate.currentUser.updateUsername(usernameSnapshot: snapshot)
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
  
    @IBAction func logOffPressed(_ sender: UIButton) {
        try! Auth.auth().signOut()
        dismiss(animated: true, completion: nil)
    }
    
    func iconImageTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        print("iconImage is tapped")
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary;
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            iconImageView.image = image
            self.dismiss(animated: true, completion: nil)
            self.appDelegate.currentUser.uploadIcon(image: image)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        settingsTableViewController = segue.destination as! SettingsTableViewController
        settingsTableViewController.parentController = self
    }
}


