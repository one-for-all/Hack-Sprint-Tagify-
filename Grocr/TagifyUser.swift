/*
 * Copyright (c) 2015 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Foundation

class TagifyUser {
  let uid: String
  let email: String
  var username: String
  var following = Set<String>()
  var followedBy = Set<String>()
//  var following = Set<TagifyUser>()
//  var followedBy = Set<TagifyUser>()
  
  init(authData: User) {
    uid = authData.uid
    email = authData.email!
    self.username = self.email
    self.setUpdates()
  }
  init(uid: String) {
    self.email = ""
    self.username = ""
    self.uid = uid
    self.setUpdates()
  }
  func setUpdates() {
    guard self.uid != "" else { return }
    let ref = Database.database().reference().child("userProfiles/\(self.uid)")
    let usernameRef = ref.child("username")
    usernameRef.observe(.value, with: { snapshot in
      if snapshot.exists() {
        self.username = snapshot.value as! String
      }
    })
    let followingRef = ref.child("following")
    followingRef.observe(.value, with: { snapshot in
      self.following = Set<String>()
      if snapshot.exists() {
        for uid in snapshot.value as! [String: Bool] {
          print("following : \(uid.key)")
          self.following.insert(uid.key)
        }
      }
    })
    let followedByRef = ref.child("followedBy")
    followedByRef.observe( .value, with: { snapshot in
      self.followedBy = Set<String>()
      if snapshot.exists() {
        for uid in snapshot.value as! [String: Bool] {
          print("followed by : \(uid.key)")
          self.followedBy.insert(uid.key)
        }
      }
    })
  }
  func follow(uid: String, ref: DatabaseReference) {
    self.following.insert(uid)
    ref.child("\(self.uid)/following").setValue([uid: true])
  }
  func unfollow(uid: String, ref: DatabaseReference) {
    self.following.remove(uid)
    ref.child("\(self.uid)/following").setValue([uid: NSNull()])
  }
  func setUsername(username: String, ref: DatabaseReference) {
    self.username = username
    ref.child("\(self.uid)/username").setValue(username)
  }
  func followedBy(uid: String, ref: DatabaseReference) {
    self.followedBy.insert(uid)
    ref.child("\(self.uid)/followedBy").setValue([uid: true])
  }
  func unfollowedBy(uid: String, ref: DatabaseReference) {
    self.followedBy.remove(uid)
    ref.child("\(self.uid)/followedBy").setValue([uid: NSNull()])
  }
  // To Do: Add song tags for user
  func add(tag: String, forSong song: Song) {
    Database.database().reference(withPath: "userTags").child("\(self.uid)/\(tag)").setValue([song.key: true])
    Database.database().reference(withPath: "userSongs").child("\(self.uid)/\(song.key)").setValue([tag: true])
  }
  func remove(tag: String, forSong song: Song) {
    Database.database().reference(withPath: "userTags").child("\(self.uid)/\(tag)").setValue([song.key: NSNull()])
    Database.database().reference(withPath: "userSongs").child("\(self.uid)/\(song.key)").setValue([tag: NSNull()])
  }
}

extension TagifyUser: Hashable {
  var hashValue: Int {
    return uid.hashValue
  }
  static func == (lhs: TagifyUser, rhs: TagifyUser) -> Bool {
    return lhs.uid == rhs.uid
  }
}
