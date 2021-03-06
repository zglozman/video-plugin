//
//  VideoManager.h
//  VideoStreamer
//
//  Created by Artur Khidirnabiev on 07.11.15.
//  Copyright © 2015 arche. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CDVStreamViewController.h"

@class CDVStreamViewController;

@interface VideoManager : NSObject
+ (id)shared;

- (BOOL)serverStatus;
- (void)startTcpConnect:(NSString *)host andLocalPort:(NSNumber *)localport callback:(void (^)(NSString * globalIP, NSNumber * globalPort, NSNumber * localPort))callback error:(void (^)())error;
- (void)startHttpServerWithPort:(NSNumber *)port callback:(void (^)(NSDictionary *))callback;
- (void)stopHttpServer:(void (^)())callback;

@property CDVStreamViewController *streamController;

// event
@property (nonatomic, copy) void (^onCloseCallback)(void);
@end
