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

    static let usernameKey = "lastLoggedInUsername"

    @IBOutlet var usernameInput: UITextField!
    @IBOutlet var passwordInput: UITextField!
    @IBOutlet var loginButton: SimpleRoundedButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.usernameInput.delegate = self
        self.passwordInput.delegate = self
        self.usernameInput.text = UserDefaults.standard.string(forKey: LoginViewController.usernameKey)
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .all
        } else {
            return .portrait
        }
    }
    
    @IBAction func login() {
        self.loginButton.startAnimating()
        let username = usernameInput.text
        let password = passwordInput.text
        
        UserDefaults.standard.set(username, forKey: LoginViewController.usernameKey)
        
        LoginHelper.login(username: username, password: password)
            .onSuccess {
                ApiHelper.updateData(includingAuthorization: false)
                self.performSegue(withIdentifier: "loginDidSucceed", sender: nil)
            }
            .onFailure { error in
                DispatchQueue.main.async {
                    self.loginButton.stopAnimating()
                    self.show(error: error)
                }
            }
    }

    func show(error: SCError) {
        self.usernameInput.shake()
        self.passwordInput.shake()
    }
    
}

extension LoginViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == self.usernameInput { // Switch focus to other text field
            self.passwordInput.becomeFirstResponder()
        } else if textField == self.passwordInput {
            self.login()
        }
        return true
    }

}
