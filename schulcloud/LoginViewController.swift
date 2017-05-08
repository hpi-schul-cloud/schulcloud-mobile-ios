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

class LoginViewController: UIViewController {

    @IBOutlet var usernameTextArea: UITextField!
    @IBOutlet var passwordTextArea: UITextField!
    
    let defaults = UserDefaults.standard
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        log.info("Hello there!")
        if let username = defaults.string(forKey: "username") {
            var account = SchulCloudAccount(username: username, userId: nil, accessToken: nil)
            account.loadAccessTokenFromKeychain()
            guard account.accessToken != nil else {
                log.error("Could not load account from Keychain!")
                return
            }
            self.performSegue(withIdentifier: "showLoginSuccess", sender: account)
        }
        
    }
    
    @IBOutlet var loginButton: SimpleRoundedButton!
    @IBOutlet var loginErrorLabel: UILabel!
    
    @IBAction func login() {
        loginButton.startAnimating()
        loginErrorLabel.isHidden = true
        let username = usernameTextArea.text
        let password = passwordTextArea.text
        
        let parameters: Parameters = [
            "username": username as Any,
            "password": password as Any
        ]
        
        let loginEndpoint = Constants.backend.url.appendingPathComponent("authentication/")
        Alamofire.request(loginEndpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            self.loginButton.stopAnimating()
            
            if let json = response.result.value as? [String: Any] {
                if let accessToken = json["accessToken"] as? String {
                    self.saveLoginAndContinue(username: username!, accessToken: accessToken)
                } else if let errorMessage = json["message"] as? String, errorMessage != "Error" {
                    let error = LoginError.loginFailed(errorMessage)
                    self.show(error: error)
                } else if json["code"] as? Int == 401 {
                    let error = LoginError.wrongCredentials
                    self.show(error: error)
                } else {
                    let error = LoginError.unknown
                    self.show(error: error)
                }
                
            } else {
                let error = response.error!
                self.show(error: error)
            }
        }
    }

    func show(error: Error) {
        loginErrorLabel.text = error.localizedDescription
        loginErrorLabel.isHidden = false
    }
    
    func saveLoginAndContinue(username: String, accessToken: String) {
        let account = SchulCloudAccount(username: username, userId: nil, accessToken: accessToken)
        defaults.set(account.username, forKey: "username")
        try! account.createInSecureStore()
        
        performSegue(withIdentifier: "showLoginSuccess", sender: account)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "showLoginSuccess") {
//            let message = sender as! String
//            
//            let successVC = segue.destination
//            let label = successVC.view.viewWithTag(1) as! UILabel
//            label.text = message
        }
    }
    

}

enum LoginError: Error {
    case loginFailed(String)
    case wrongCredentials
    case unknown
}

extension LoginError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .loginFailed(let message):
            return "Fehler: \(message)"
        case .wrongCredentials:
            return "Fehler: Falsche Anmeldedaten"
        case .unknown:
            return "Unbekannter Fehler"
        }
    }
}
