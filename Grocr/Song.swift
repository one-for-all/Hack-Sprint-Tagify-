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

class Song {
  
  let key: String
  let name: String
  let addedByUser: String
  let ref: DatabaseReference?
  var completed: Bool = false
  var tags = Set<String>()
  var imageSource = "music.jpg"
  
  init(name: String, addedByUser: String, completed: Bool, key: String = "") {
    self.key = key
    self.name = name
    self.addedByUser = addedByUser
    self.completed = completed
    self.ref = nil
  }
  
  init(name: String) {
    self.name = name
    self.key = ""
    self.addedByUser = ""
    self.ref = nil
  }
  init(name: String, key: String) {
    self.name = name
    self.key = key
    self.addedByUser = ""
    self.ref = nil
  }
  init(name: String, imageSource: String) {
    self.name = name
    self.key = ""
    self.addedByUser = ""
    self.ref = nil
    self.imageSource = imageSource
  }
  
  init(snapshot: DataSnapshot) {
    key = snapshot.key
    let snapshotValue = snapshot.value as! [String: AnyObject]
    name = snapshotValue["name"] as! String
    let snapshotTags = snapshotValue["tags"] as! [String: Bool]
    for key in snapshotTags.keys {
      tags.insert("#"+key)
    }
    ref = snapshot.ref
    addedByUser = ""
  }
  
  func toAnyObject() -> Any {
    var songObj: [String: Any] = [:]
    songObj["name"] = name
    var tagDict = [String: Bool]()
    for tag in tags {
      tagDict[tag.substring(from: tag.index(tag.startIndex, offsetBy: 1))] = true
    }
    songObj["tags"] = tagDict
    print("this song is:")
    print("name: \(songObj["name"]!)")
    print("tags:")
    let tagsD = songObj["tags"] as! [String: Bool]
    for tag in tagsD.keys {
      print(tag)
    }
    return songObj
  }
  
}

