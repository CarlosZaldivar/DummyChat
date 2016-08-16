//
//  RegistrationViewController.swift
//  DummyChat
//

import UIKit

import Alamofire

class RegistrationViewController: UIViewController, UITextFieldDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        registerButton.userInteractionEnabled = false
        title = "Registration"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    
    @IBAction func usernameEditing(sender: UITextField) {
        let username = usernameTextField.text!
        let password = passwordTextField.text!
        
        if !username.isEmpty && !password.isEmpty {
            registerButton.userInteractionEnabled = true
        } else {
            registerButton.userInteractionEnabled = false
        }
    }
    @IBAction func passwordEditing(sender: UITextField) {
        let username = usernameTextField.text!
        let password = passwordTextField.text!
        
        if !username.isEmpty && !password.isEmpty {
            registerButton.userInteractionEnabled = true
        } else {
            registerButton.userInteractionEnabled = false
        }
    }
    
    @IBAction func register(sender: UIButton) {
        let parameters = [
            "username": usernameTextField.text!,
            "password": passwordTextField.text!
        ]
        
        Alamofire.request(.POST, "http://172.16.85.1:4040/register", parameters: parameters, encoding: .JSON)
            .validate()
            .responseString { response in
                if !response.result.isSuccess {
                    let alert = UIAlertController(title: "Error", message: "This is  username is already taken", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Got it", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                } else {
                    let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                    
                    let loginViewController = storyBoard.instantiateViewControllerWithIdentifier("LoginView") as UIViewController
                    self.navigationController?.pushViewController(loginViewController, animated: true)
                }
        }
    }
}
