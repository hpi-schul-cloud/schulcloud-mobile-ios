//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit

class LoginViewController: UIViewController {

    static let usernameKey = "lastLoggedInUsername"

    @IBOutlet private weak var usernameInput: UITextField!
    @IBOutlet private weak var passwordInput: UITextField!
    @IBOutlet private weak var loginButton: LoadingButton!
    @IBOutlet private weak var inputContainer: UIStackView!
    @IBOutlet private weak var centerInputConstraints: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.usernameInput.delegate = self
        self.passwordInput.delegate = self
        self.usernameInput.text = UserDefaults.standard.string(forKey: LoginViewController.usernameKey)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(adjustViewForKeyboardShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(adjustViewForKeyboardHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
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

    @IBAction private func login() {
        guard let username = self.usernameInput.text, let password = self.passwordInput.text else {
            self.showLoginError()
            return
        }

        UserDefaults.standard.set(username, forKey: LoginViewController.usernameKey)
        self.login(username: username, password: password)
    }

    @IBAction private func loginAsTestStudent() {
        self.login(account: Brand.default.testAccounts.student)
    }

    @IBAction private func loginAsTestTeacher() {
        self.login(account: Brand.default.testAccounts.teacher)
    }

    private func login(account: TestAccount) {
        self.login(username: account.username, password: account.password)
    }

    private func login(username: String, password: String) {
        self.loginButton.startAnimation()
        LoginHelper.login(username: username, password: password).onSuccess {
            DispatchQueue.main.async {
                if self.isBeingPresented {
                    self.dismiss(animated: true)
                } else {
                    self.performSegue(withIdentifier: R.segue.loginViewController.loginDidSucceed, sender: nil)
                }
            }
        }.onFailure { _ in
            DispatchQueue.main.async {
                self.loginButton.stopAnimation()
                self.showLoginError()
            }
        }
    }

    func showLoginError() {
        self.usernameInput.shake()
        self.passwordInput.shake()
    }

    @objc func adjustViewForKeyboardShow(_ notification: Notification) {
        // On some devices, the keyboard can overlap with some UI elements. To prevent this, we move
        // the `inputContainer` upwards. The other views will repostion accordingly.
        let keyboardFrameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        let keyboardHeight = keyboardFrameValue?.cgRectValue.size.height ?? 0.0

        let contentInset: CGFloat
        if #available(iOS 11.0, *) {
            contentInset = self.view.safeAreaInsets.top + self.view.safeAreaInsets.bottom
        } else {
            contentInset = self.topLayoutGuide.length + self.bottomLayoutGuide.length
        }

        let viewHeight = self.view.frame.size.height - contentInset

        let overlappingOffset = 0.5 * viewHeight - keyboardHeight - 0.5 * self.inputContainer.frame.size.height
        self.centerInputConstraints.constant = min(overlappingOffset, 0)  // we only want to move the container upwards

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    @objc func adjustViewForKeyboardHide(_ notification: Notification) {
        self.centerInputConstraints.constant = 0

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    @IBAction private func tapOnBackground(_ sender: UITapGestureRecognizer) {
        self.usernameInput.resignFirstResponder()
        self.passwordInput.resignFirstResponder()
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
