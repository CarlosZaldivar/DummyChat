//
//  SocketManager.swift
//  DummyChat
//

import UIKit

import Starscream

class SocketManager: NSObject {
    static let sharedInstance = SocketManager();
    
    var socket: WebSocket = WebSocket(url: NSURL(string: "ws://10.154.82.146:4040/ws")!);
    
    
    func establishConnection(username: NSString, password: NSString) {
        let loginString = NSString(format: "%@:%@", username, password)
        let loginData = loginString.dataUsingEncoding(NSUTF8StringEncoding)
        let base64EncodedCredential = loginData!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
        
        socket.headers["Authorization"] = "Basic \(base64EncodedCredential)"
        socket.connect()
    }
    
    func closeConnection() {
        socket.disconnect()
    }
}
