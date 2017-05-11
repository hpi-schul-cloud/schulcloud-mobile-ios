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
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBOutlet var loginButton: SimpleRoundedButton!
    @IBOutlet var loginErrorLabel: UILabel!
    
    @IBAction func login() {
        loginButton.startAnimating()
        loginErrorLabel.isHidden = true
        let username = usernameTextArea.text
        let password = passwordTextArea.text
        
        LoginHelper.login(username: username, password: password)
            .onSuccess {
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


