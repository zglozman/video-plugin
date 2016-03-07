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

#import "HTTPServer.h"
#import "DDKeychain.h"

#import "testCocoaBinarySocket-Swift.h"

@interface VideoManager ()
@end

@implementation VideoManager{
    HTTPServer *httpServer;
    TcpProxyClient *client;
}

- (BOOL)serverStatus{
    return httpServer.isRunning;
}

- (void)stopHttpServer:(void (^)())callback{
    [client disconnectAllSockets];
    [httpServer stop];
    httpServer = nil;
}

- (void)startTcpConnect:(NSString *)host andLocalPort:(NSNumber *)localport callback:(void (^)(NSString * globalIP, NSNumber * globalPort, NSNumber * localPort))callback error:(void (^)())error{
    client = [[TcpProxyClient alloc] init];
    
    [client connect:host localPort:localport onConnect:^{
        [client createPublicTcpServer];
    } onTcpConnected:^(NSString * globalIP, NSNumber * globalPort, NSNumber * localPort) {
        callback(globalIP, globalPort, localPort);
    } onError:^{
        error();
    }];
}

- (void)startHttpServerWithPort:(NSNumber *)port callback:(void (^)(NSDictionary *))callback{
    [self copyFiles];
    
    NSError * error;
    httpServer = [[HTTPServer alloc] init];
    DDKeychain *keychain = [[DDKeychain alloc] init];
    
    [httpServer setPort:port.intValue];
    
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
    NSString * documentsCertPath  = [basePath stringByAppendingPathComponent:@"cert"];
    
    NSError *error = nil;
    BOOL success = [fm removeItemAtPath:documentsWebPath error:&error];
    if (!success || error) {
        // something went wrong
    }
    
    NSString * resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString * bundleWebPath = [resourcePath stringByAppendingPathComponent:@"Web"];
    NSString * bundleCertPath = [resourcePath stringByAppendingPathComponent:@"cert"];
    
    
    [[NSFileManager defaultManager] copyItemAtPath:bundleWebPath toPath:documentsWebPath error:&error];
    [[NSFileManager defaultManager] copyItemAtPath:bundleCertPath toPath:documentsCertPath error:&error];
    NSLog(@"Copy of files finished with %@", error.domain  );
    //        NSArray * directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsWebPath error:&error];
}

- (NSString *)getIPAddress{
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    NSString *wifiAddress = nil;
    NSString *cellAddress = nil;
    
    // retrieve the current interfaces - returns 0 on success
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            sa_family_t sa_type = temp_addr->ifa_addr->sa_family;
            if(sa_type == AF_INET || sa_type == AF_INET6) {
                NSString *name = [NSString stringWithUTF8String:temp_addr->ifa_name];
                NSString *addr = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)]; // pdp_ip0
                //NSLog(@"NAME: \"%@\" addr: %@", name, addr); // see for yourself
                
                if([name isEqualToString:@"en0"]) {
                    // Interface is the wifi connection on the iPhone
                    wifiAddress = addr;
                } else
                    if([name isEqualToString:@"pdp_ip0"]) {
                        // Interface is the cell connection on the iPhone
                        cellAddress = addr;
                    }
            }
            temp_addr = temp_addr->ifa_next;
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    NSString *addr = wifiAddress ? wifiAddress : cellAddress;
    
    return addr;
}

@end
