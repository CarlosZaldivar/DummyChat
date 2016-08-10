//
//  LoginViewController.swift
//  DummyChat
//

import UIKit

import Starscream

class LoginViewController: UIViewController, WebSocketDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        loginButton.userInteractionEnabled = false
        SocketManager.sharedInstance.socket.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    @IBAction func usernameEditing(sender: UITextField) {
        let username = usernameTextField.text!
        let password = passwordTextField.text!
        
        if !username.isEmpty && !password.isEmpty {
            loginButton.userInteractionEnabled = true
        } else {
            loginButton.userInteractionEnabled = false
        }
    }
    
    @IBAction func passwordEditing(sender: UITextField) {
        let username = usernameTextField.text!
        let password = passwordTextField.text!
        
        if !username.isEmpty && !password.isEmpty {
            loginButton.userInteractionEnabled = true
        } else {
            loginButton.userInteractionEnabled = false
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

    @IBAction func login(sender: UIButton) {
        let username = usernameTextField.text!
        let password = passwordTextField.text!
        
        SocketManager.sharedInstance.establishConnection(username, password: password)
    }
    
    func websocketDidConnect(socket: WebSocket) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        
        let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("ConversationsView") as UIViewController
        self.presentViewController(nextViewController, animated:true, completion:nil)
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        let alert = UIAlertController(title: "Error", message: "Could not login with provided credentials", preferredStyle: UIAlertControllerStyle.Alert)
       alert.addAction(UIAlertAction(title: "Got it", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
    }
}
