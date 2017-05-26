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
  var following = Set<TagifyUser>()
  var followedBy = Set<TagifyUser>()
  
  init(authData: User) {
    uid = authData.uid
    email = authData.email!
    self.username = self.email
  }
  
  init(uid: String) {
    self.uid = uid
    self.email = ""
    self.username = ""
  }
  
  init(uid: String, email: String) {
    self.uid = uid
    self.email = email
    self.username = email
  }
  func follow(user: TagifyUser, ref: DatabaseReference) {
    self.following.insert(user)
    ref.child("\(self.uid)/following").setValue([user.uid: true])
  }
  func unfollow(user: TagifyUser, ref: DatabaseReference) {
    self.following.remove(user)
    ref.child("\(self.uid)/following").setValue([user.uid: NSNull()])
  }
  func setUsername(username: String, ref: DatabaseReference) {
    self.username = username
    ref.child("\(self.uid)/username").setValue(username)
  }
  func followedBy(user: TagifyUser, ref: DatabaseReference) {
    self.followedBy.insert(user)
    print("\(self.email) is followed by \(user.email)")
    ref.child("\(self.uid)/followedBy").setValue([user.uid: true])
  }
  func unfollowedBy(user: TagifyUser, ref: DatabaseReference) {
    self.followedBy.remove(user)
    ref.child("\(self.uid)/followedBy").setValue([user.uid: NSNull()])
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
