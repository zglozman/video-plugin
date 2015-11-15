//
//  HttpConnectonHandler.m
//  Kickflip
//
//  Created by Zeev Glozman on 10/29/15.
//  Copyright © 2015 Kickflip. All rights reserved. //

@import  Foundation;
#import "HttpConnectionHandler.h"
#import "HTTPResponeWithHeaders.h"
#import "MyWebSocket.h"
#import "HTTPMessage.h"
#import <HTTPConnection.h>
#import "HTTPDynamicFileResponse.h"
#import "GCDAsyncSocket.h"
// Log levels: off, error, warn, info, verbose
// Other flags: trace


@implementation HTTPConnectionHandler

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    // Use HTTPConnection's filePathForURI method.
    // This method takes the given path (which comes directly from the HTTP request),
    // and converts it to a full path by combining it with the configured document root.
    //
    // It also does cool things for us like support for converting "/" to "/index.html",
    // and security restrictions (ensuring we don't serve documents outside configured document root folder).
    
    NSString *filePath = [self filePathForURI:path];
    
    // Convert to relative path
    
    NSString *documentRoot = [config documentRoot];
    
    if (![filePath hasPrefix:documentRoot])
    {
        // Uh oh.
        // HTTPConnection's filePathForURI was supposed to take care of this for us.
        return nil;
    }
    
    NSString *relativePath = [filePath substringFromIndex:[documentRoot length]];
    NSLog(@"HTTP Server Recivied request for %@", relativePath);
    if ([relativePath isEqualToString:@"/crossdomain.xml"])
    {
        NSLog(@"[%p]: Serving up dynamic content", self);
        
        NSString *string = @"<?xml version=\"1.0\"?>"
        "<!DOCTYPE cross-domain-policy SYSTEM \"http://www.adobe.com/xml/dtds/cross-domain-policy.dtd\">"
        "<cross-domain-policy>"
        "<allow-access-from domain=\"*\" secure=\"false\" />"
        "</cross-domain-policy>";
        
        NSData *response = [string dataUsingEncoding:NSUTF8StringEncoding];
        HTTPResponeWithHeaders *httpResp = [[HTTPResponeWithHeaders alloc] initWithData:response];
        
        return httpResp ;
    }
    else if ([relativePath isEqualToString:@"/Web/_main.js"]) {
        //The socket.js file contains a URL template that needs to be completed:
        //
        // ws = new WebSocket("%%WEBSOCKET_URL%%");
        //
        // We need to replace "%%WEBSOCKET_URL%%" with whatever URL the server is running on.
        // We can accomplish this easily with the HTTPDynamicFileResponse class,
        // which takes a dictionary of replacement key-value pairs,
        // and performs replacements on the fly as it uploads the file.
        
        NSString *wsLocation;
        
        NSString *wsHost = [request headerField:@"Host"];
        if (wsHost == nil)
        {
            NSString *port = [NSString stringWithFormat:@"%hu", [asyncSocket localPort]];
            wsLocation = [NSString stringWithFormat:@"ws://localhost:%@/service", port];
        }
        else
        {
            wsLocation = [NSString stringWithFormat:@"ws://%@/service", wsHost];
        }
        
        NSDictionary *replacementDict = [NSDictionary dictionaryWithObject:wsLocation forKey:@"WEBSOCKET_URL"];
        
        return [[HTTPDynamicFileResponse alloc] initWithFilePath:[self filePathForURI:path]
                                                   forConnection:self
                                                       separator:@"%%"
                                           replacementDictionary:replacementDict];
        
    }
    
    return [super httpResponseForMethod:method URI:path];
}

- (WebSocket *)webSocketForURI:(NSString *)path
{
    NSLog(@"[%p]: webSocketForURI: %@", self, path);
    
    if([path isEqualToString:@"/service"])
    {
        NSLog(@"MyHTTPConnection: Creating MyWebSocket...");
        
        return [[MyWebSocket alloc] initWithRequest:request socket:asyncSocket];
    }
    
    return [super webSocketForURI:path];
}

@end