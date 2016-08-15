//
//  ConversationsTableViewController.swift
//  DummyChat
//

import UIKit

import Starscream
import SwiftyJSON

class ConversationsTableViewController: UITableViewController, WebSocketDelegate {
    
    var selectedConversation: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Conversations"
    }
    
    override func viewWillAppear(animated: Bool) {
        //self.tableView.
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        SocketManager.sharedInstance.socket.delegate = self
        let json: JSON =  ["requestType": "getConversations"]
        SocketManager.sharedInstance.socket.writeString(json.rawString()!)
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        case "getConversationsResponse":
            if json["status"].string == "ok" {
                addConversations(json["conversations"])
            }
        case "newConversation":
            addConversation(json["conversation"])
        default:
            ()
        }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
    }
    
    func addConversations(json: JSON) {
        var indexPaths = [NSIndexPath]()
        var i = SharedData.instance.conversations.count
        for (_, conversationJson):(String, JSON) in json {
            let id = conversationJson["id"].int!
            if !SharedData.instance.conversations.contains({conversation in conversation.id == id}) {
                
                let messagesJson = conversationJson["messages"].arrayValue
                let messages = getMessages(messagesJson)
                let participantsJson = conversationJson["participants"].arrayValue
                let participants = getParticipants(participantsJson)
                let conversation = Conversation(id: id, messages: messages, participants: participants)
                SharedData.instance.conversations.append(conversation)
                indexPaths.append(NSIndexPath(forRow: i, inSection: 0))
                i += 1
            }
        }
        
        tableView.beginUpdates()
        
        tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Right)
        
        tableView.endUpdates()
    }
    
    func addConversation(conversationJson: JSON) {
        let messages = getMessages(conversationJson["messages"].arrayValue)
        let participants = getParticipants(conversationJson["participants"].arrayValue)
        let conversation = Conversation(id: conversationJson["id"].int!, messages: messages, participants: participants)
        
        SharedData.instance.conversations.append(conversation)
        
        let insertionIndexPath = NSIndexPath(forRow: SharedData.instance.conversations.count - 1, inSection: 0)
        
        tableView.insertRowsAtIndexPaths([insertionIndexPath], withRowAnimation: .Automatic)
    }
    
    func getMessages(messagesJson: [JSON]) -> [Message] {
        var messages = [Message]()
        for messageJson in messagesJson {
            let message = Message(id: messageJson["id"].int!, authorId: messageJson["authorId"].int!, conversationId: messageJson["conversationId"].int!, content: messageJson["content"].string!)
            messages.append(message)
        }
        return messages
    }
    
    func getParticipants(participantsJson: [JSON]) -> [User] {
        var participants = [User]()
        for participantJson in participantsJson {
            let participant = User(username: participantJson["username"].string!, id: participantJson["id"].int!)
            participants.append(participant)
        }
        return participants
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedConversation = indexPath.row
        performSegueWithIdentifier("conversationSegue", sender: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destinationVC = segue.destinationViewController as? ConversationTableViewController
        destinationVC!.conversationIndex = selectedConversation!
        destinationVC!.conversationsController = self
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SharedData.instance.conversations.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ConversationCell", forIndexPath: indexPath) as! ConversationCell
        
        let conversation = SharedData.instance.conversations[indexPath.row]
        if conversation.participants[0].id == SharedData.instance.user!.id {
            cell.userLabel.text = conversation.participants[1].username
        } else {
            cell.userLabel.text = conversation.participants[0].username
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterViewWithIdentifier("headerId")
    }
}

class ConversationCell: UITableViewCell {
    @IBOutlet weak var userLabel: UILabel!
}