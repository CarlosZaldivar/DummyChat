//
//  LoginViewController.swift
//  DummyChat
//

import UIKit

import Starscream
import SwiftyJSON

class LoginViewController: UIViewController, WebSocketDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        loginButton.userInteractionEnabled = false
        SocketManager.sharedInstance.socket.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        // Clear data
        SharedData.instance.user = nil
        SharedData.instance.conversations = [Conversation]()
        SocketManager.sharedInstance.closeConnection()
        SocketManager.sharedInstance.socket.delegate = self
        super.viewWillAppear(animated)
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
        let json: JSON =  ["requestType": "getUser", "username": usernameTextField.text!]
        SocketManager.sharedInstance.socket.writeString(json.rawString()!)
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        if error != nil {
            switch error!.code {
            case 401:
                let alert = UIAlertController(title: "Error", message: "Could not login with provided credentials", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Got it", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            case 61:
                let alert = UIAlertController(title: "Error", message: "Could not connect to server", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Got it", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            default:
                ()
            }
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        let json: JSON = JSON(data: text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        
        let messageType = json["messageType"].string!
        switch messageType {
        case "getUserResponse":
            if json["status"].string == "ok" {
                var user = json["user"]
                SharedData.instance.user = User(username: user["username"].string!, id: user["id"].int!)
                goToConversations()
            }
        default:
            ()
        }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
    }
    
    func goToConversations() {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        
        let conversationsViewController = storyBoard.instantiateViewControllerWithIdentifier("ConversationsView") as UIViewController
        
        self.navigationController?.pushViewController(conversationsViewController, animated: true)
    }
}
