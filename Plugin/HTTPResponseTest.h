//
//  HTTPResponseTest
//  Kickflip
//
//  Created by Zeev Glozman on 10/29/15.
//  Copyright © 2015 Kickflip. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "HTTPServer.h"
#import "HTTPResponse.h"
#import "HTTPConnection.h"

@class Connection;

//
// This class is a UnitTest for the delayResponseHeaders capability of HTTPConnection
//

@interface HTTPResponseTest : NSObject <HTTPResponse>
{
    // Parents retain children, children do NOT retain parents
    
    __unsafe_unretained HTTPConnection *connection;
    dispatch_queue_t responseQueue;
    
    BOOL readyToSendResponseHeaders;
}

- (id)initWithConnection:(HTTPConnection *)connection;

@end

