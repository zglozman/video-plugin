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
    controller.manager = videomanager;
    
    [self.viewController presentViewController:controller animated:YES completion:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            videomanager = [[VideoManager alloc] init];
            
            [videomanager startTcpConnect:@"https://prod.luckyqr.io" callback:^(NSString *globalIP, NSNumber *globalPort) {
                NSDictionary *global = @{@"ip": globalIP, @"port": [globalPort stringValue]};
                
                [videomanager startHttpServerWithPort:globalPort callback:^(NSDictionary *info) {
                    [controller startVideoStream];
                    
                    NSDictionary *response = @{@"global": global, @"local": info};
                    
                    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
                    
                    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                }];
            }];
        });
    }];
}

@end
