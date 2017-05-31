//
//  CollectionView.swift
//  Tagify
//
//  Created by 迦南 on 5/19/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import UIKit

class CollectionView: UICollectionView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    var currentSelectedCell: CollectionViewCell = CollectionViewCell()
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        addLongPressGesture()
        addTapGesture()
        let popMenu = UIMenuController.shared
        let menuRemoveItem = UIMenuItem(title: "remove", action: #selector(SongViewController.removeTag))
        let menuTagSearch = UIMenuItem(title: "search", action: #selector(SongViewController.searchSongsWithSelectedTag))
        popMenu.menuItems = [menuTagSearch, menuRemoveItem]

    }
    
    func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapped(_:)))
        self.addGestureRecognizer(tapGesture)
    }
    func tapped(_ gesture: UIGestureRecognizer) {
        let point = gesture.location(in: self)
        if let indexPath = self.indexPathForItem(at: point) {
            print("tapped inside cells")
            if let cell = self.cellForItem(at: indexPath) as? CollectionViewCell {
                self.currentSelectedCell = cell
                becomeFirstResponder()
                let x = cell.frame.origin.x+cell.frame.width/2
                let y = cell.frame.origin.y
                let popMenu = UIMenuController.shared
                popMenu.setTargetRect(CGRect(x: x, y: y, width: 20, height: 10), in: self)
                popMenu.setMenuVisible(true, animated: true)
            }
        } else {
            print("tapped outside cells")
            UIMenuController.shared.setMenuVisible(false, animated: true)
            if let songViewController = self.delegate as? SongViewController {
                songViewController.dismissKeyboard()
            }
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
}

