//
//  LoginViewController.swift
//  schulcloud
//
//  Created by Carl Gödecken on 05.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit
import Alamofire
import SimpleRoundedButton

class LoginViewController: UIViewController {

    @IBOutlet var usernameTextArea: UITextField!
    @IBOutlet var passwordTextArea: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBOutlet var loginButton: SimpleRoundedButton!
    @IBAction func login() {
        loginButton.startAnimating()
        let username = usernameTextArea.text
        let password = passwordTextArea.text
        
        let parameters: Parameters = [
            "username": username as Any,
            "password": password as Any
        ]
        
        let loginEndpoint = Constants.backend.url.appendingPathComponent("authentication/")
        Alamofire.request(loginEndpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            
            if let json = response.result.value as? [String: Any],
                let accessToken = json["accessToken"] as? String {
                self.performSegue(withIdentifier: "showLoginSuccess", sender: accessToken)
            }
        }
    }

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "showLoginSuccess") {
            let message = sender as! String
            
            let successVC = segue.destination
            let label = successVC.view.viewWithTag(1) as! UILabel
            label.text = message
        }
    }
    

}
