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

import UIKit

class LoginViewController: UIViewController {
  
  // MARK: Constants
  let loginToList = "LoginToList"
  let loginToSongView = "LoginToSongView"
  let userProfilesRef: DatabaseReference = Database.database().reference(withPath: "userProfiles")
  
  // MARK: Outlets
  @IBOutlet weak var textFieldLoginEmail: UITextField!
  @IBOutlet weak var textFieldLoginPassword: UITextField!
  
  // MARK: Actions
  @IBAction func loginDidTouch(_ sender: AnyObject) {
    Auth.auth().signIn(withEmail: textFieldLoginEmail.text!,
                           password: textFieldLoginPassword.text!) { user, error in
                            if error == nil {
                              print("Welcome \(user!.email!)")
                              self.clearTextField()
                            } else {
                              if let errCode = AuthErrorCode(rawValue: error!._code) {
                                print("Sign In Error: \(errCode)")
                              }
                            }
                            
    }
  }
//  @IBAction func loginDidTouch(_ sender: AnyObject) {
//    performSegue(withIdentifier: loginToList, sender: nil)
//  }
  
  @IBAction func signUpDidTouch(_ sender: AnyObject) {
    let alert = UIAlertController(title: "Register",
                                  message: "Register",
                                  preferredStyle: .alert)
    
    let saveAction = UIAlertAction(title: "Save", style: .default)
          { action in
            
            // 1
            let emailField = alert.textFields![0]
            let passwordField = alert.textFields![1]
            
            // 2
            Auth.auth().createUser(withEmail: emailField.text!, password: passwordField.text!)
                { user, error in
                  if error == nil {
                    // 3
                    if let user = user {
                      self.clearTextField()
                      print("We have new user! \(user.email!)")
                      self.userProfilesRef.child("\(user.uid)/email").setValue(emailField.text!)
                      self.userProfilesRef.child("\(user.uid)/username").setValue(emailField.text!)
                    }
                    Auth.auth().signIn(withEmail: self.textFieldLoginEmail.text!,
                                           password: self.textFieldLoginPassword.text!)
                    print("Create User Successful")
                  } else {
                    if let errCode = AuthErrorCode(rawValue: error!._code) {
                      switch errCode {
                      case .invalidEmail:
                        print("invalid email")
                      case .emailAlreadyInUse:
                        print("in use")
                      default:
                        print("Create User Error: \(error!)")
                      }
                    }
                  }
            }
            
    }
    
    let cancelAction = UIAlertAction(title: "Cancel",
                                     style: .default)
    
    alert.addTextField { textEmail in
      textEmail.placeholder = "Enter your email"
    }
    
    alert.addTextField { textPassword in
      textPassword.isSecureTextEntry = true
      textPassword.placeholder = "Enter your password"
    }
    
    alert.addAction(saveAction)
    alert.addAction(cancelAction)
    
    present(alert, animated: true, completion: nil)
  }
  
}

extension LoginViewController {
  func addHideKeyboardOnTap()
  {
    let tap: UITapGestureRecognizer = UITapGestureRecognizer(
      target: self,
      action: #selector(LoginViewController.dismissKeyboard))
    
    view.addGestureRecognizer(tap)
  }
  
  func dismissKeyboard()
  {
    view.endEditing(true)
  }
}

extension LoginViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField == textFieldLoginEmail {
      textFieldLoginPassword.becomeFirstResponder()
    }
    if textField == textFieldLoginPassword {
      textField.resignFirstResponder()
    }
    return true
  }
  func clearTextField() {
    self.textFieldLoginEmail.text = ""
    self.textFieldLoginPassword.text = ""
  }
}

extension LoginViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    // 1
    Auth.auth().addStateDidChangeListener() { auth, user in
      // 2
      if user != nil {
        // 3
        self.performSegue(withIdentifier: self.loginToSongView, sender: nil)
      }
    }
    self.addHideKeyboardOnTap()
  }
}
