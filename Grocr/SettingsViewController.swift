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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        iconImageView.layer.cornerRadius = iconImageView.frame.height/2
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.iconImageTapped(_:)))
        iconImageView.addGestureRecognizer(tapRecognizer)
        
        // Download User Profile image
        let userIconPath = "\(Auth.auth().currentUser!.uid)/userIcon.jpg"
        let reference = storageRef.child(userIconPath)
        reference.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("got image")
                self.iconImageView.image = UIImage(data: data!)
            }
        }
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
            let data = UIImageJPEGRepresentation(image, 0.8)!
            let userIconPath = "\(Auth.auth().currentUser!.uid)/userIcon.jpg"
            let metaData = StorageMetadata()
            metaData.contentType = "image/jpg"
            self.storageRef.child(userIconPath).putData(data, metadata: metaData){(metaData,error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                } else{
                    //store downloadURL
                    let downloadURL = metaData!.downloadURL()!.absoluteString
                    self.userProfilesRef.child(Auth.auth().currentUser!.uid).updateChildValues(["userIconURL": downloadURL])
                }
            }
        }
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

extension SettingsViewController {
    func searchUserWith(username: String) -> [User] {
        var searchedUsers = [User]()
        return searchedUsers
    }
}

