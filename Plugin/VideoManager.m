//
//  VideoManager.m
//  VideoStreamer
//
//  Created by Artur Khidirnabiev on 07.11.15.
//  Copyright © 2015 arche. All rights reserved.
//

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

- (void)startHttpServer{
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
    //        NSArray * directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsWebPath error:&error];
}

- (void)dealloc{
    NSLog(@"Kill server");
}
@end
