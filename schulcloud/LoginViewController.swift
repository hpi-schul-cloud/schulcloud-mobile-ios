//
//  LoginViewController.swift
//  schulcloud
//
//  Created by Carl Gödecken on 05.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit
import Alamofire
import Locksmith
import SimpleRoundedButton
import JWTDecode

class LoginViewController: UIViewController {

    @IBOutlet var usernameTextArea: UITextField!
    @IBOutlet var passwordTextArea: UITextField!
    
    let defaults = UserDefaults.standard
    let usernameKey = "lastLoggedInUsername"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameTextArea.delegate = self
        passwordTextArea.delegate = self
        usernameTextArea.text = defaults.string(forKey: usernameKey)
    }
    
    @IBOutlet var loginButton: SimpleRoundedButton!
    @IBOutlet var loginErrorLabel: UILabel!
    
    @IBAction func login() {
        loginButton.startAnimating()
        loginErrorLabel.isHidden = true
        let username = usernameTextArea.text
        let password = passwordTextArea.text
        
        defaults.set(username, forKey: usernameKey)
        
        LoginHelper.login(username: username, password: password)
            .onSuccess {
                ApiHelper.updateData(includingAuthorization: false)
                self.performSegue(withIdentifier: "loginDidSucceed", sender: nil)
            }
            .onFailure { error in
                self.loginButton.stopAnimating()
                self.show(error: error)
            }
    }

    func show(error: Error) {
        loginErrorLabel.text = error.localizedDescription
        loginErrorLabel.isHidden = false
    }
    
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == usernameTextArea { // Switch focus to other text field
            passwordTextArea.becomeFirstResponder()
        } else if textField == passwordTextArea {
            login()
        }
        return true
    }
}
