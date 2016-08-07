//
//  RegistrationViewController.swift
//  DummyChat
//
//  Created by Jan on 07/08/16.
//

import UIKit

import Alamofire

class RegistrationViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBAction func register(sender: UIButton) {
        let parameters = [
            "username": usernameTextField.text!,
            "password": passwordTextField.text!
        ]
        
        Alamofire.request(.POST, "http://192.168.43.246:4040/register", parameters: parameters, encoding: .JSON)
    }
}
