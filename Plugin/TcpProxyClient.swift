//
//  TcpProxyClient.swift
//  TcpClient
//
//  Created by Artur Khidirnabiev on 12.12.15.
//
//

import UIKit

class TcpProxyClient: NSObject {
    var host: String? = "localhost"
    var port: NSNumber?
    var localPort: NSNumber?
    
    var endPoint: String
    var connected: Bool = false
    
    
    var socket: SocketIOClient?
    var sockets: Array<TcpAsyncSocket> = Array<TcpAsyncSocket>()
    
    var onTcpConnected: ((globalIP: String, globalPort: NSNumber, localPort: NSNumber) -> Void)?
    
    override init() {
        self.endPoint = ""
        super.init()
    }
    
    func connect(endpoint: String!, localPort: NSNumber, onConnect: () -> Void, onTcpConnected: (globalIP: String, globalPort: NSNumber, localPort: NSNumber) -> Void) {
        
        self.onTcpConnected = onTcpConnected
        self.endPoint = endpoint
        self.localPort = localPort
        
        self.socket = SocketIOClient(socketURL: self.endPoint, options: [.Log(true), .Nsp("/TcpServerWS"), .ForceWebsockets(true)])
        
        NSLog("TcpProxyClient connecting to %@", self.endPoint)
        
        self.socket!.on("connect") {data, ask in
            NSLog("TcpProxyClient connected")
            
            self.connected = true
            
            onConnect()
        }
        
        self.socket!.on("TcpServerCreated"){data, ask in
            //self.handleTcpProxySendEvents(data, callback: { () -> Void in
            
            let lock: NSLock = NSLock()
            
            let dict: NSDictionary! = data[0] as! NSDictionary
            
            let realWorldClientPort: NSNumber? = dict.valueForKey("port") as? NSNumber
            let realWorldClientIp: String? = dict.valueForKey("publicIp") as? String
            
            self.port = realWorldClientPort
            
            if (self.onTcpConnected != nil){
                self.onTcpConnected!(globalIP: realWorldClientIp!, globalPort: realWorldClientPort!, localPort: localPort)
            }
            
            
            NSLog("http://%@:%@/Web/index.html", realWorldClientIp!, realWorldClientPort!.stringValue)
            
            self.socket!.on("create_connection") {data, ask in
                let dict: NSDictionary! = data[0] as! NSDictionary
                let serverSideSocketId: String!  = dict.valueForKey("tcpSocketId") as! String
                
                NSLog("First SocketID: %@", serverSideSocketId)
                
                let asyncSocket = TcpAsyncSocket()
                self.atomicAddSocketToArray(asyncSocket, sockets_array: &self.sockets, lock: lock)
                
                asyncSocket.connect(self.host, onPort: self.localPort!.unsignedShortValue, socketId: serverSideSocketId, onConnect: { (sockConnect: TcpAsyncSocket) -> Void in
                    //on data
                    asyncSocket.onRead = { (sock: TcpAsyncSocket, data: NSData, withTag: Int) in
                        NSLog("onAsyncSocketRead: id: %@", sock.serverSideSocketId!)
                        
                        let temp = ["tcpSocketId": sock.serverSideSocketId!, "payload": data]
                        dispatch_async(dispatch_get_main_queue(),  {
                            NSLog("Emmitting data");
                            self.socket!.emit("data", temp)
                        });
                        
                    }
                    
                    asyncSocket.onDidDisconnect = { (sock: TcpAsyncSocket) in
                        NSLog("onAsyncSocketDisconnect ServerSideSocketId %@", sock.serverSideSocketId!)
                        self.socket!.emit("disconnect_client", ["tcpSocketId": sock.serverSideSocketId!]);
                        self.atomicRemoveSocketAtIdex(sock, sockets_array: &self.sockets, lock: lock);
                    }
                    
                    }, onErrorConnect: { (sock: TcpAsyncSocket) -> Void in
                        self.socket!.emit("disconnect_client", ["tcpSocketId": sock.serverSideSocketId!])
                });
                NSLog("Adding socket.io handlers ")
            }
            
            self.socket!.on("data") {data, ask in
                let dict: NSDictionary! = data[0] as! NSDictionary
                let remoteSocketId: String! = dict.valueForKey("tcpSocketId") as! String
                let serverSocket:TcpAsyncSocket! = self.atomicGetSocketFromArray(remoteSocketId, sockets_array: self.sockets, lock: lock)!
                if (serverSocket != nil){
                    let data: NSData = dict.valueForKey("payload") as! NSData
                    
                    serverSocket.write(data, withTag:1)
                }
            }
            
            self.socket!.on("reconnect"){ data, ask in
                NSNotificationCenter.defaultCenter().postNotificationName("SOCKET_RECONNECT", object: self.socket)
                
                NSLog("Reconnecting")
            }
            
            self.socket!.on("end") { data, ask in
                NSLog("TCP Client disconnected from remote server")
                
                let dict: NSDictionary! = data[0] as! NSDictionary
                let rSockId: String! = dict.valueForKey("tcpSocketId") as! String
                let serverSocket:TcpAsyncSocket! = self.atomicGetSocketFromArray(rSockId, sockets_array: self.sockets, lock: lock)!
                serverSocket.disconnect()
                self.atomicRemoveSocketAtIdex(serverSocket, sockets_array: &self.sockets, lock: lock);
                
                
            }
            self.socket!.on("error") {data, ask in
                
                //let dict: String = data[1] as! String
                //let a: NSString! = NSString(data: b, encoding: NSUTF8StringEncoding)
                
                NSLog("SocketIO Error %@", dict)
                lock.lock()
                for (_, value) in self.sockets.enumerate() {
                    let sock: TcpAsyncSocket = value as TcpAsyncSocket
                    sock.disconnect()
                    
                    self.sockets.removeAtIndex(0)
                }
                lock.unlock()
            }
        }
        
        
        self.socket!.connect()
    }
    
    func handleTcpProxySendEvents(data: NSArray!, callback: () -> Void){
        
    }
    
    func createPublicTcpServer(){
        if (self.connected){
            NSLog("Emitting Create Tcp Server %@", self.socket!.sid!);
            
            self.socket!.emit("createTcpServer", ["LocalSocketId": self.socket!.sid!])
        }
    }
    
    func atomicGetSocketFromArray(socketid: String, sockets_array: Array<TcpAsyncSocket>, lock: NSLock) -> TcpAsyncSocket?{
        
        lock.lock()
        for (_, value) in sockets_array.enumerate() {
            
            let tempSock: TcpAsyncSocket = value as TcpAsyncSocket
            
            if (socketid == tempSock.serverSideSocketId){
                lock.unlock()
                return tempSock;
            }
        }
        lock.unlock()
        return nil;
        //        sockets.append(asyncSocket)
    }
    
    func atomicAddSocketToArray(socket: TcpAsyncSocket, inout sockets_array: Array<TcpAsyncSocket>, lock: NSLock){
        lock.lock()
        sockets_array.append(socket)
        lock.unlock();
    }
    
    func atomicRemoveSocketAtIdex(socket: TcpAsyncSocket, inout sockets_array: Array<TcpAsyncSocket>, lock: NSLock){
        for (index, value) in sockets_array.enumerate() {
            
            let tempSock: TcpAsyncSocket = value as TcpAsyncSocket
            
            if (socket == tempSock){
                lock.lock()
                sockets_array.removeAtIndex(index)
                lock.unlock();
                break
            }
        }
    }
    
    func disconnectAllSockets() -> Void{
        for (_, value) in self.sockets.enumerate() {
            let socket: TcpAsyncSocket = value as TcpAsyncSocket
            
            
            NSLog("AsyncSocket call disckonnect")
            
            socket.disconnect();
        }
        
        if (self.socket != nil){
            NSLog("Socket call disckonnect")
            self.socket!.close();
        }
    }
}
