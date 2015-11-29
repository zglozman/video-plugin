//
//  VideoManager.m
//  VideoStreamer
//
//  Created by Artur Khidirnabiev on 07.11.15.
//  Copyright © 2015 arche. All rights reserved.
//
#import <ifaddrs.h>
#import <arpa/inet.h>

#import "VideoManager.h"

#import "HttpConnectionHandler.h"
#import "MyWebSocket.h"
#import "HTTPServer.h"

@interface VideoManager ()
@end

@implementation VideoManager{
    HTTPServer *httpServer;
}

- (BOOL)serverStatus{
    return httpServer.isRunning;
}

- (void)stopHttpServer:(void (^)())callback{
    [httpServer stop];
    
    callback();
}

- (void)startHttpServer:(void (^)(NSDictionary *info))callback{
    [self copyFiles];
    
    NSError * error;
    httpServer = [[HTTPServer alloc] init];
    [httpServer setPort:8080];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSLog(@"base path is %@", basePath);
    [httpServer setDocumentRoot:basePath];
    [httpServer setConnectionClass:[HTTPConnectionHandler class]];
    
    if([httpServer start:&error])
    {
        NSLog(@"Started HTTP Server on port %d", [httpServer listeningPort]);
        NSString *port = [NSString stringWithFormat:@"%d", [httpServer listeningPort]];
        NSString *host = [self getIPAddress];
        
        
        NSArray *values = [NSArray arrayWithObjects:host, port, nil];
        NSArray *keys   = [NSArray arrayWithObjects:@"ip", @"port", nil];
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjects:values forKeys:keys];
        
        callback(dict);
        
    }
    else
    {
        NSLog(@"Error starting HTTP Server: %@", error);
    }
}

- (void)copyFiles {
    // Override point for customization after application launch.
    
    //[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"moved_files_to_documents_web"];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString * documentsWebPath = [basePath stringByAppendingPathComponent:@"Web"];
    
    NSError *error = nil;
    BOOL success = [fm removeItemAtPath:documentsWebPath error:&error];
    if (!success || error) {
        // something went wrong
    }
    
    NSString * resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString * bundleWebPath = [resourcePath stringByAppendingPathComponent:@"Web"];
    
    
    [[NSFileManager defaultManager] copyItemAtPath:bundleWebPath toPath:documentsWebPath error:&error];
    NSLog(@"Copy of files finished with %@", error.domain  );
}

- (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
    
}
@end
