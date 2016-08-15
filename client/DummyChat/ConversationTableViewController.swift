//
//  ConversationTableViewController.swift
//  DummyChat
//

import UIKit

import Starscream
import SwiftyJSON

class ConversationTableViewController: UITableViewController, WebSocketDelegate {
    
    var conversationIndex: Int?
    var conversationsController: ConversationsTableViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if SharedData.instance.conversations[conversationIndex!].participants[0].username == SharedData.instance.user!.username {
            title = "Conversation with " + SharedData.instance.conversations[conversationIndex!].participants[1].username
        } else {
            title = "Conversation with " + SharedData.instance.conversations[conversationIndex!].participants[0].username
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        SocketManager.sharedInstance.socket.delegate = self
        super.viewWillAppear(animated)
    }
    
    func websocketDidConnect(socket: WebSocket) {
        
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        let json: JSON = JSON(data: text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        
        let messageType = json["messageType"].string!
        switch messageType {
        case "newMessage":
            addMessage(json["message"])
        case "newConversation":
            conversationsController!.addConversation(json["conversation"])
        case "sentMessageResponse":
            if json["status"].string == "ok" {
                addMessage(json["message"])
            }
            ()
        default:
            ()
        }
    }
    
    func addMessage(messageJson: JSON) {
        let id = messageJson["id"].int!
        let authorId = messageJson["authorId"].int!
        let conversationId = messageJson["conversationId"].int!
        let content = messageJson["content"].string!
        
        let message = Message(id: id, authorId: authorId, conversationId: conversationId, content: content)
        
        SharedData.instance.conversations[conversationIndex!].messages.append(message)
        
        let insertionIndexPath = NSIndexPath(forRow: SharedData.instance.conversations[conversationIndex!].messages.count - 1, inSection: 0)
        
        tableView.insertRowsAtIndexPaths([insertionIndexPath], withRowAnimation: .Automatic)
    }
     
    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SharedData.instance.conversations[conversationIndex!].messages.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MessageCell", forIndexPath: indexPath) as! MessageCell
        
        let currentChatMessage = SharedData.instance.conversations[conversationIndex!].messages[indexPath.row]
        
        let messageContent = currentChatMessage.content
        
        let i = SharedData.instance.conversations[conversationIndex!].participants.indexOf({$0.id == currentChatMessage.authorId})
        let messageAuthor = SharedData.instance.conversations[conversationIndex!].participants[i!].username
        
        if messageAuthor == SharedData.instance.user!.username {
            cell.authorLabel.textAlignment = NSTextAlignment.Right
            cell.contentLabel.textAlignment = NSTextAlignment.Right
        } else {
            cell.authorLabel.textAlignment = NSTextAlignment.Left
            cell.contentLabel.textAlignment = NSTextAlignment.Left
        }
        
        cell.authorLabel.text = messageAuthor
        cell.contentLabel.text = messageContent
        
        //cell.lblChatMessage.textColor = UIColor.darkGrayColor()
        
        return cell
    }

    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBAction func sendMessage(sender: UIButton) {
        if (messageTextField.text != nil) {
            messageTextField.text = nil
            let sentMessage = Message(id: -1, authorId: SharedData.instance.user!.id, conversationId: SharedData.instance.conversations[conversationIndex!].id, content: messageTextField.text!)
            
            let json: JSON =  ["requestType": "sendMessage", "message": ["authorId": sentMessage.authorId, "conversationId": sentMessage.conversationId, "content": sentMessage.content]]
            SocketManager.sharedInstance.socket.writeString(json.rawString()!)
        }
    }
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

class MessageCell: UITableViewCell {
    
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
}

class ConversationFooter: UIView {
    
}