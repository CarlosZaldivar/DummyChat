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
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: SharedData.instance.conversations[conversationIndex!].messages.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
        case "newConversation":
            conversationsController!.addConversation(json["conversation"])
        case "sendMessageResponse":
            if json["status"].string == "ok" {
                addMessage(json["message"])
            }
            ()
        case "startConversationResponse":
            if json["status"].string == "ok" {
                SharedData.instance.conversations[conversationIndex!].id = json["conversation"]["id"].int!
                addMessage(json["conversation"]["messages"].arrayValue[0])
                SharedData.instance.conversations[conversationIndex!].savedInDatabase = true
            }
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
        let index = SharedData.instance.conversations.indexOf({$0.id == conversationId})
        
        SharedData.instance.conversations[index!].messages.append(message)
        
        if index == conversationIndex {
            let insertionIndexPath = NSIndexPath(forRow: SharedData.instance.conversations[conversationIndex!].messages.count - 1, inSection: 0)
        
            tableView.insertRowsAtIndexPaths([insertionIndexPath], withRowAnimation: .Automatic)
        }
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
        
        return cell
    }

    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBAction func sendMessage(sender: UIButton) {
        if (messageTextField.text != nil && messageTextField.text! != "") {
            if SharedData.instance.conversations[conversationIndex!].id != -1 {
                sendSingleMessage()
            } else {
                startNewConversation()
            }
        }
    }
    
    func sendSingleMessage() {
        let sentMessage = Message(id: -1, authorId: SharedData.instance.user!.id, conversationId: SharedData.instance.conversations[conversationIndex!].id, content: messageTextField.text!)
        
        let json: JSON =  ["requestType": "sendMessage", "message": ["authorId": sentMessage.authorId, "conversationId": sentMessage.conversationId, "content": sentMessage.content]]
        SocketManager.sharedInstance.socket.writeString(json.rawString()!)
        messageTextField.text = nil
    }
    
    func startNewConversation() {
        let conversation = SharedData.instance.conversations[conversationIndex!]
        let recipient: User
        if conversation.participants[0].id == SharedData.instance.user!.id {
            recipient = conversation.participants[1]
        } else {
            recipient = conversation.participants[0]
        }
        let json: JSON =  ["requestType": "startConversation", "message": messageTextField.text!, "recipient": recipient.username]
        SocketManager.sharedInstance.socket.writeString(json.rawString()!)
        messageTextField.text = nil
    }
}

class MessageCell: UITableViewCell {
    
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
}

class ConversationFooter: UIView {
    
}