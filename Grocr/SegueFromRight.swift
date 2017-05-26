//
//  SegueFromRight.swift
//  Tagify
//
//  Created by 迦南 on 5/26/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import UIKit

class SegueFromRight: UIStoryboardSegue {
    override func perform()
    {
        let src = self.source
        let dst = self.destination
        
        let transition = CATransition()
        transition.duration = 0.25
        transition.type = kCATransitionPush
        transition.subtype = kCATransitionFromRight
        src.view.window!.layer.add(transition, forKey: kCATransition)
        src.present(dst, animated: false, completion: nil)
    }
}
