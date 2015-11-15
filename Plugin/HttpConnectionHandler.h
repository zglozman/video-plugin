//
//  HttpConnectionHandler.h
//  Kickflip
//
//  Created by Zeev Glozman on 10/29/15.
//  Copyright © 2015 Kickflip. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HTTPConnection.h>


@class MyWebSocket;


@interface HTTPConnectionHandler : HTTPConnection {
    MyWebSocket *ws;

}


@end

