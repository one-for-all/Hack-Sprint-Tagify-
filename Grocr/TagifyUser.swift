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
    self.updateAll()
  }
  init(uid: String) {
    self.email = ""
    self.username = ""
    self.uid = uid
    //self.updateAll()
  }
  func updateFollowing(followingSnapshot: DataSnapshot) {
    guard self.uid != "" else { return }
    self.following = Set<String>()
    if followingSnapshot.exists() {
      for uid in followingSnapshot.value as! [String: Bool] {
        print("following : \(uid.key)")
        self.following.insert(uid.key)
      }
    }
  }
  func updateFollowers(followerSnapshot: DataSnapshot) {
    guard self.uid != "" else { return }
    self.followedBy = Set<String>()
    if followerSnapshot.exists() {
      for uid in followerSnapshot.value as! [String: Bool] {
        print("followed by : \(uid.key)")
        self.followedBy.insert(uid.key)
      }
    }
  }
  func updateUsername(usernameSnapshot: DataSnapshot) {
    guard self.uid != "" else { return }
    if usernameSnapshot.exists() {
      self.username = usernameSnapshot.value as! String
    }
  }
  func updateAll() {
    let ref = Database.database().reference().child("\(self.uid)")
    let usernameRef = ref.child("username")
    usernameRef.observeSingleEvent(of: .value, with: { snapshot in
      self.updateUsername(usernameSnapshot: snapshot)
    })
    let followingRef = ref.child("following")
    followingRef.observeSingleEvent(of: .value, with: { snapshot in
      self.updateFollowing(followingSnapshot: snapshot)
    })
    let followersRef = ref.child("followedBy")
    followersRef.observeSingleEvent(of: .value, with: { snapshot in
      self.updateFollowers(followerSnapshot: snapshot)
    })
  }
  func follow(uid: String) {
    self.following.insert(uid)
    let ref = Database.database().reference().child("userProfiles")
    ref.child("\(self.uid)/following/\(uid)").setValue(true)
  }
  func unfollow(uid: String, ref: DatabaseReference) {
    self.following.remove(uid)
    print("unfollowing: \(uid)")
    ref.child("\(self.uid)/following/\(uid)").setValue(NSNull())
  }
  func setUsername(username: String, ref: DatabaseReference) {
    self.username = username
    ref.child("\(self.uid)/username").setValue(username)
  }
  func followedBy(uid: String, ref: DatabaseReference) {
    self.followedBy.insert(uid)
    ref.child("\(self.uid)/followedBy/\(uid)").setValue(true)
  }
  func unfollowedBy(uid: String, ref: DatabaseReference) {
    self.followedBy.remove(uid)
    ref.child("\(self.uid)/followedBy/\(uid)").setValue(NSNull())
  }
  // To Do: Add song tags for user
  func add(tag: String, forSong song: Song) {
    Database.database().reference(withPath: "userTags").child("\(self.uid)/\(tag)/\(song.key)").setValue(true)
    Database.database().reference(withPath: "userSongs").child("\(self.uid)/\(song.key)/\(tag)").setValue(true)
  }
  func remove(tag: String, forSong song: Song) {
    Database.database().reference(withPath: "userTags").child("\(self.uid)/\(tag)/\(song.key)").setValue(NSNull())
    Database.database().reference(withPath: "userSongs").child("\(self.uid)/\(song.key)/\(tag)").setValue(NSNull())
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
