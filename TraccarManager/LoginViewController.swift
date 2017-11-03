//
// Copyright 2016 Anton Tananaev (anton.tananaev@gmail.com)
// Copyright 2016 William Pearse (w.pearse@gmail.com)
// Copyright 2017 Sergey Kruzhkov (s.kruzhkov@gmail.com)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit
import MBProgressHUD
import LGAlertView

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}


let TCDefaultsServerKey = "DefaultsServerKey"
let TCDefaultsEmailKey = "DefaultsEmailKey"
let TCDefaultsPassKey = "DefaultsPassKey"

class LoginViewController: UIViewController, UITextFieldDelegate, LGAlertViewDelegate {
    
    @IBOutlet var serverField: UITextField!
    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var rememberSwitch: UISwitch!
    
    var trustDomain = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // user can't do anything until they're logged-in
        navigationItem.setHidesBackButton(true, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
        let d = UserDefaults.standard
        if let s = d.string(forKey: TCDefaultsServerKey) {
            self.serverField.text = s
        }
        if let e = d.string(forKey: TCDefaultsEmailKey) {
            self.emailField.text = e
        }
        
        if self.serverField.text?.count > 0 && self.emailField.text?.count > 0 {
            if let p = KeychainWrapper.standard.string(forKey: TCDefaultsPassKey) {
                self.passwordField.text = p
                self.loginButton.becomeFirstResponder()
            } else {
                self.passwordField.becomeFirstResponder()
            }
        }
        
    }
    
    @IBAction func loginButtonPressed() {
        
        MBProgressHUD.showAdded(to: view, animated: true)
        
        WebService.sharedInstance.authenticate(serverField!.text!, email: emailField!.text!, password: passwordField!.text!, onFailure: { error in
            
            DispatchQueue.main.async(execute: {
                
                MBProgressHUD.hide(for: self.view, animated: true)
                
                if error.code == -1202 {
                    self.trustDomain = (URL(string: self.serverField.text!)?.host)!
                    let dialog = LGAlertView.init(viewAndTitle: "Error", message: error.localizedDescription, style: LGAlertViewStyle.alert, view: nil, buttonTitles: ["Allow"], cancelButtonTitle: nil, destructiveButtonTitle: "Cancel")
                    dialog.delegate = self
                    dialog.showAnimated()
                } else {
                    let dialog = LGAlertView.init(viewAndTitle: "Error", message: error.localizedDescription, style: LGAlertViewStyle.alert, view: nil, buttonTitles: ["OK"], cancelButtonTitle: nil, destructiveButtonTitle: nil)
                    dialog.showAnimated()
                }
                
            })
            
        }, onSuccess: { (user) in
            
            DispatchQueue.main.async(execute: {
                
                // save server, user
                let d = UserDefaults.standard
                d.setValue(self.serverField!.text!, forKey: TCDefaultsServerKey)
                d.setValue(self.emailField!.text!, forKey: TCDefaultsEmailKey)
                d.synchronize()
                
                //save password to keychain
                if self.rememberSwitch.isOn {
                    KeychainWrapper.standard.set(self.passwordField.text!, forKey: TCDefaultsPassKey)
                } else {
                    KeychainWrapper.standard.removeObject(forKey: TCDefaultsPassKey)
                }
                
                
                MBProgressHUD.hide(for: self.view, animated: true)
                
                self.dismiss(animated: true, completion: nil)
                
                self.performSegue(withIdentifier: "ShowMap", sender: self)
            })
        }
        )
    }
    
    func alertView(_ alertView: LGAlertView, clickedButtonAt index: UInt, title: String?) {
        let d = UserDefaults.standard
        d.setValue(trustDomain, forKey: Definitions.TCDefaultsTrustDomain)
        d.setValue(self.serverField!.text!, forKey: TCDefaultsServerKey)
        d.setValue(self.emailField!.text!, forKey: TCDefaultsEmailKey)
        d.synchronize()
        
        //save password to keychain
        if self.rememberSwitch.isOn {
            KeychainWrapper.standard.set(self.passwordField.text!, forKey: TCDefaultsPassKey)
        } else {
            KeychainWrapper.standard.removeObject(forKey: TCDefaultsPassKey)
        }
        
        let dialog = LGAlertView.init(viewAndTitle: "", message: trustDomain + " add to trusted domains. Restart application", style: LGAlertViewStyle.alert, view: nil, buttonTitles: ["OK"], cancelButtonTitle: nil, destructiveButtonTitle: nil)
        dialog.showAnimated()
    }
    // move between text fields when return button pressed, and login
    // when you press return on the password field
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == serverField {
            emailField.becomeFirstResponder()
        } else if textField == emailField {
            passwordField.becomeFirstResponder()
        } else {
            passwordField.resignFirstResponder()
            loginButtonPressed()
        }
        return true
    }
    
}
