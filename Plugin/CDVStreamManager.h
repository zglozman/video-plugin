//
//  CDVStreamManager.h
//  VideoStreamerCordovaPlugin
//
//  Created by Artur Khidirnabiev on 08.11.15.
//  Copyright © 2015 arche. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "VideoManager.h"
#import <Cordova/CDVPlugin.h>

@interface CDVStreamManager : CDVPlugin

- (void)startHttpServer:(CDVInvokedUrlCommand*)command;
- (void)openStreamController:(CDVInvokedUrlCommand*)command;
@end
