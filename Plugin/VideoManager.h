//
//  VideoManager.h
//  VideoStreamer
//
//  Created by Artur Khidirnabiev on 07.11.15.
//  Copyright © 2015 arche. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoManager : NSObject
- (BOOL)serverStatus;
- (void)startTcpConnect:(NSString *)host callback:(void (^)(NSString * globalIP, NSNumber * globalPort))callback;
- (void)startHttpServer:(NSNumber *)port callback:(void (^)(NSDictionary *info))callback;
- (void)stopHttpServer:(void (^)())callback;
@end
