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

    @IBOutlet weak var usernameInput: UITextField!
    @IBOutlet weak var passwordInput: UITextField!
    @IBOutlet weak var loginButton: SimpleRoundedButton!
    @IBOutlet weak var inputContainer: UIStackView!
    @IBOutlet weak var centerInputConstraints: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.usernameInput.delegate = self
        self.passwordInput.delegate = self
        self.usernameInput.text = UserDefaults.standard.string(forKey: LoginViewController.usernameKey)

        NotificationCenter.default.addObserver(self, selector: #selector(self.adjustViewForKeyboardShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.adjustViewForKeyboardHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
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

    func adjustViewForKeyboardShow(_ notification: Notification) {
        // On some devices, the keyboard can overlap with some UI elements. To prevent this, we move
        // the `inputContainer` upwards. The other views will repostion accordingly.
        let keyboardFrameValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue
        let keyboardHeight = keyboardFrameValue?.cgRectValue.size.height ?? 0.0

        let contentInset: CGFloat
        if #available(iOS 11.0, *) {
            contentInset = self.view.safeAreaInsets.top + self.view.safeAreaInsets.bottom
        } else {
            contentInset = self.topLayoutGuide.length + self.bottomLayoutGuide.length
        }

        let viewHeight = self.view.frame.size.height - contentInset

        let overlappingOffset = 0.5*viewHeight - keyboardHeight - 0.5*self.inputContainer.frame.size.height - 8.0
        self.centerInputConstraints.constant = min(overlappingOffset, 0)  // we only want to move the container upwards

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    func adjustViewForKeyboardHide(_ notification: Notification) {
        self.centerInputConstraints.constant = 0

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
    
}

extension LoginViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.usernameInput { // Switch focus to other text field
            self.passwordInput.becomeFirstResponder()
        } else if textField == self.passwordInput {
            textField.resignFirstResponder()
            self.login()
        }
        return true
    }

}
