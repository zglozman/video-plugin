//
//  TcpAsyncSocket.swift
//  testCocoaBinarySocket
//
//  Created by MacBook Air MD760 on 16.12.15.
//  Copyright © 2015 Zeev Glozman. All rights reserved.
//

import Foundation

class TcpAsyncSocket: NSObject, GCDAsyncSocketDelegate{
    let TIMEOUT: NSTimeInterval = -1
    var TAG: Int = 0
    
    var serverSideSocketId: String?
    var asyncSocket: GCDAsyncSocket?
    
    // callback
    var onAsyncConnect: ((sockConnect: TcpAsyncSocket) -> Void)?
    var onAsyncErrorConnect: ((sock: TcpAsyncSocket) -> Void)?
    var onDidDisconnect: ((sock: TcpAsyncSocket) -> Void)?
    
    var onRead: ((sock: TcpAsyncSocket, data: NSData, withTag: Int) -> Void)?
    var onWrite: ((sock: TcpAsyncSocket, data: NSData, withtag: Int) -> Void)?
    
    override init() {
        self.asyncSocket = GCDAsyncSocket()
        super.init()
        self.asyncSocket!.setDelegate(self, delegateQueue: dispatch_get_main_queue())
        
    }
    
    func connect(host: String!, onPort: UInt16, socketId: String!, onConnect: (sockConnect: TcpAsyncSocket) -> Void, onErrorConnect: (sock: TcpAsyncSocket) -> Void){
        
        
        let random: NSNumber! = NSNumber(unsignedInt: arc4random())
        
        self.TAG = random.integerValue
        
        self.serverSideSocketId = socketId
        
        self.onAsyncConnect     = onConnect
        self.onAsyncErrorConnect  = onErrorConnect
        
        do {
            try self.asyncSocket!.connectToHost(host, onPort: onPort)
        } catch let error as NSError  {
            print(error)
            
            self.errorConnect()
        }
        self.asyncSocket!.readDataWithTimeout(self.TIMEOUT, tag:self.TAG )
    }
    
    func write(data: NSData!, withTag: Int!){
        let a: NSString? = NSString(data: data, encoding: NSUTF8StringEncoding)
        
        if (a != nil){
            //NSLog(a! as String)
        }
        
        
        
        self.asyncSocket!.writeData(data, withTimeout:self.TIMEOUT, tag:self.TAG )
        
        if (self.onWrite != nil){
            self.onWrite!(sock: self, data: data, withtag: self.TAG )
        }
    }
    
    func disconnect(){
        self.asyncSocket!.disconnectAfterReadingAndWriting();
        
        self.onDidDisconnect!(sock: self)
    }
    
    func errorConnect(){
        self.onAsyncErrorConnect!(sock: self)
        
        NSLog("Async error connect: %@", self.serverSideSocketId!)
    }
    /*
    func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        NSLog("onDidDisconnect: %@", err)
        self.onDidDisconnect!(sock: self);
    }*/
    
    func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        NSLog("Async didConnectToHost: %@", self.serverSideSocketId!)
        self.onAsyncConnect!(sockConnect: self)
    }
    
    func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        let lenght: NSNumber = NSNumber(integer: data.length)
        
        //        self.asyncSocket!.readDataToData(data, withTimeout:15, tag: 1)
        //        self.asyncSocket!.readDataToLength(lenght.unsignedIntegerValue, withTimeout:self.TIMEOUT, tag: self.TAG )
        
        //let a: NSData = data
        //        let s: NSString! = NSString(data: data, encoding: NSUTF8StringEncoding)
        NSLog("Reading data from socket: %d", lenght.unsignedIntegerValue)
        dispatch_async(dispatch_get_main_queue(), {
            self.asyncSocket!.readDataWithTimeout(-1, tag: self.TAG);
        });
        self.onRead!(sock: self, data: data, withTag: self.TAG )
        
    }
    
    
}
