//
//  UnwindSegueToRight.swift
//  Tagify
//
//  Created by 迦南 on 5/26/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import UIKit

class UnwindSegueToRight: UIStoryboardSegue {
    override func perform()
    {
        let src = self.source
        let dst = self.destination
        
        let transition = CATransition()
        transition.duration = 0.25
        transition.type = kCATransitionPush
        transition.subtype = kCATransitionFromLeft
        src.view.window!.layer.add(transition, forKey: kCATransition)
        src.dismiss(animated: false, completion: nil)
    }
}
