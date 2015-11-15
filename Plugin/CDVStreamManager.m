//
//  CDVStreamManager.m
//  VideoStreamerCordovaPlugin
//
//  Created by Artur Khidirnabiev on 08.11.15.
//  Copyright © 2015 arche. All rights reserved.
//

#import "CDVStreamManager.h"
#import "CDVStreamViewController.h"

@implementation CDVStreamManager{
    VideoManager *videomanager;
}

- (CDVPlugin *)initWithWebView:(UIWebView *)theWebView{
    NSLog(@"init plugin");
    return self;
}

- (void)startHttpServer:(CDVInvokedUrlCommand*)command{
    
}

- (void)openStreamController:(CDVInvokedUrlCommand*)command{
    CDVStreamViewController *controller = [[CDVStreamViewController alloc] init];
    
    [self.viewController presentViewController:controller animated:YES completion:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            videomanager = [[VideoManager alloc] init];
            [videomanager startHttpServer:^(NSDictionary *info) {
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:info];
                
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            }];
        });
    }];
}

@end
