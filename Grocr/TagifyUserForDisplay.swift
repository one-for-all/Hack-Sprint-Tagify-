//
//  TagifyUserForDisplay.swift
//  Tagify
//
//  Created by 迦南 on 5/28/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import Foundation
import SDWebImage

class TagifyUserForDisplay {
    let uid: String
    var username: String = ""
    var email = ""
    var userIcon: UIImage = UIImage()
    var userIconImageView = UIImageView()
    var listenedTo = false
    let storageRef = Storage.storage().reference()
    init(uid: String) {
        self.uid = uid
    }
    init(userSnapshot snapshot: DataSnapshot, completion: @escaping (Void) -> Void) {
        self.uid = snapshot.key
        self.username = snapshot.childSnapshot(forPath: "username").value as? String ?? ""
        self.email = snapshot.childSnapshot(forPath: "email").value as? String ?? ""
        let userIconSmallPath = "\(self.uid)/userIconSmall.jpg"
        let reference = self.storageRef.child(userIconSmallPath)
        reference.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                print(error.localizedDescription)
                self.userIcon = UIImage(named: "music.jpg")!
            } else {
                print("got image")
                self.userIcon = UIImage(data: data!)!
            }
            completion()
        }
//        userIconImageView.sd_setImage(with: reference, placeholderImage: UIImage(named: "music.jpg")!) { (image, error, cachedType, storageRef) in
//            self.userIconImageView.image = image
//            completion()
//        }

    }
}
