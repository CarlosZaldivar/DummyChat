//
//  ConversationsTableViewController.swift
//  DummyChat
//

import UIKit

import Starscream
import SwiftyJSON

class ConversationsTableViewController: UITableViewController, WebSocketDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerClass(Header.self, forHeaderFooterViewReuseIdentifier: "headerId")
        
        tableView.sectionHeaderHeight = 50

        SocketManager.sharedInstance.socket.delegate = self
        let json: JSON =  ["requestType": "getConversations"]
        SocketManager.sharedInstance.socket.writeString(json.rawString()!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func websocketDidConnect(socket: WebSocket) {
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        
        let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("LoginView") as UIViewController
        self.presentViewController(nextViewController, animated:true, completion:nil)
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
            break
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
                let recipient = User(username: conversationJson["recipient"]["username"].string!, id: conversationJson["recipient"]["id"].int!)
                let participants = [recipient, SharedData.instance.user!]
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
    
    func getMessages(messagesJson: [JSON]) -> [Message] {
        var messages = [Message]()
        for messageJson in messagesJson {
            let message = Message(id: messageJson["id"].int!, authorId: messageJson["authorId"].int!, conversationId: messageJson["conversationId"].int!, content: messageJson["content"].string!)
            messages.append(message)
        }
        return messages
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

// https://github.com/purelyswift/uitableview_row_insertions_programmatically/blob/master/mytableview1/ViewController.swift
class ConversationCell: UITableViewCell {
    @IBOutlet weak var userLabel: UILabel!
}

class Header: UITableViewHeaderFooterView {
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Conversations"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFontOfSize(14)
        return label
    }()
    
    func setupViews() {
        addSubview(nameLabel)
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-16-[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": nameLabel]))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": nameLabel]))
        
    }
    
}