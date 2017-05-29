//
//  UsernameViewController.swift
//  Tagify
//
//  Created by 迦南 on 5/26/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import UIKit

class UsernameViewController: UIViewController, UITextFieldDelegate {
  
    @IBOutlet weak var usernameTextField: UITextField!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        usernameTextField.text = appDelegate.currentUser.username
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @IBAction func saveButtonPressed(_ sender: Any) {
        self.appDelegate.currentUser.setUsername(username: usernameTextField.text!)
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
