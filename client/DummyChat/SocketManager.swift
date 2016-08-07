//
//  SocketManager.swift
//  DummyChat
//
//  Created by Jan on 06/08/16.
//

import UIKit

import Starscream

class SocketManager: NSObject {
    static let sharedInstance = SocketManager();
    
    override init() {
        super.init();
    }
    
    var socket: WebSocket = WebSocket(url: NSURL(string: "ws://192.168.43.246:4040/ws")!);
    
    
    func establishConnection() {
        socket.connect()
    }
    
    func closeConnection() {
        socket.disconnect()
    }
}
