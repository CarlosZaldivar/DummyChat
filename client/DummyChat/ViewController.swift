//
//  ViewController.swift
//  DummyChat
//

import UIKit

class ViewController: UIViewController {
    
    override func viewWillAppear(animated: Bool) {
        // Clear data
        SharedData.instance.user = nil
        SharedData.instance.conversations = [Conversation]()
        SocketManager.sharedInstance.closeConnection()
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
