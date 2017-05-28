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
  
  var name: String = ""
  var songWriter: String = ""
  var tags = Set<String>()
  var imageSource = "music.jpg"
  var trackId = ""
  var previewURL = ""
  
  init(trackId: String) { // for initializing empty song
    self.trackId = trackId
  }

  init(name: String, songWriter: String, trackId: String, imageSource: String, previewURL: String) {
    self.name = name
    self.songWriter = songWriter
    self.trackId = trackId
    self.imageSource = imageSource
    self.previewURL = previewURL
  }
  
  init(snapshot: DataSnapshot) {
    trackId = snapshot.key
    let snapshotValue = snapshot.value as! [String: AnyObject]
    name = snapshotValue["name"] as! String
    let snapshotTags = snapshotValue["tags"] as! [String: Bool]
    for key in snapshotTags.keys {
      tags.insert("#"+key)
    }
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
  
  func printImageUrl() {
    print(self.imageSource)
  }
}
extension Song: Hashable {
  var hashValue: Int {
    return trackId.hashValue
  }
  static func == (lhs: Song, rhs: Song) -> Bool {
    return lhs.trackId == rhs.trackId
  }
}
