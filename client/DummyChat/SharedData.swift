//
//  SharedData.swift
//  DummyChat
//

import UIKit

class SharedData: NSObject {
    static let instance = SharedData();
    
    var user: User?
    var conversations = [Conversation]()
}

struct User {
    var username: String
    var id: Int
}

struct Message {
    var id: Int
    var authorId: Int
    var conversationId: Int
    var content: String
}

struct Conversation {
    var id: Int
    var messages: [Message]
    var participants: [User]
    var savedInDatabase: Bool
}