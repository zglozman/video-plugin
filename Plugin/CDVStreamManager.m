//
//  CDVStreamManager.m
//  VideoStreamerCordovaPlugin
//
//  Created by Artur Khidirnabiev on 08.11.15.
//  Copyright © 2015 arche. All rights reserved.
//

#import "CDVStreamManager.h"
#import "CDVStreamViewController.h"

#import "MyWebSocket.h"

@implementation CDVStreamManager{
    CDVPluginResult *result;
    //VideoManager *videomanager;
}

- (CDVPlugin *)initWithWebView:(UIWebView *)theWebView{
    NSLog(@"init plugin");
    return self;
}

- (void)startHttpServer:(CDVInvokedUrlCommand*)command{

}


- (void)startServer:(VideoManager *)videomanager localPort:(NSNumber *)localPort success:(void (^) (NSDictionary *info))success{
    [videomanager startHttpServerWithPort:localPort callback:^(NSDictionary *info) {
        success(info);
    }];
}

- (void)startLocalVideoStream:(CDVInvokedUrlCommand*)command{
    VideoManager *videomanager = [VideoManager shared];
    
    NSNumber *port = @80;
    
    [self startServer:videomanager localPort:port success:^(NSDictionary *info) {
//        [controller startVideoStream];
        
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:info];
        
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)startGlobalVideoStream:(CDVInvokedUrlCommand*)command{
    VideoManager *videomanager = [VideoManager shared];
    
    NSNumber *port = @80;
    
    [videomanager startTcpConnect:@"https://prod.luckyqr.io" andLocalPort:port callback:^(NSString *globalIP, NSNumber *globalPort, NSNumber *localPort) {
        
        NSDictionary *info = @{@"ip": globalIP, @"port": globalPort};
        
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:info];
        
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    } error:^{
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)openStreamController:(CDVInvokedUrlCommand*)command{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        CDVStreamViewController *controller = [[CDVStreamViewController alloc] init];
        controller.manager = [VideoManager shared];
        
        [[NSNotificationCenter defaultCenter] addObserver:controller selector:@selector(sleep) name:UIApplicationDidEnterBackgroundNotification object:nil];
        
        [self.viewController presentViewController:controller animated:YES completion:^{
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [controller startVideoStream];
            });
        }];
        
        controller = nil;
    });
}

- (void)closeStreamController:(CDVInvokedUrlCommand *)command{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CloseStreamController" object:nil];
}

#pragma mark Events

// Open
- (void)onOpenEvent:(CDVInvokedUrlCommand *)command{
    NSString *callbackId = command.callbackId;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOpen:) name:@"OnOpenCDVStreamViewController" object:callbackId];
}

- (void)onOpen:(NSNotification *)notification{
    NSString *callbackId = notification.object;
    
    if (callbackId != nil){
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [result setKeepCallbackAsBool:YES];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }
}

// Close
- (void)onCloseEvent:(CDVInvokedUrlCommand *)command{
    NSString *callbackId = command.callbackId;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onClose:) name:@"OnCloseCDVStreamViewController" object:callbackId];
}

- (void)onClose:(NSNotification *)notification{
    NSString *callbackId = notification.object;
    
    if (callbackId != nil){
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [result setKeepCallbackAsBool:YES];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }
}

// Start Video
- (void)onStartEvent:(CDVInvokedUrlCommand *)command{
    NSString *callbackId = command.callbackId;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onStart:) name:@"OnStartCDVStreamViewController" object:callbackId];
}

- (void)onStart:(NSNotification *)notification{
    NSString *callbackId = notification.object;
    
    if (callbackId != nil){
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [result setKeepCallbackAsBool:YES];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }
}

// Pause Video
- (void)onPauseEvent:(CDVInvokedUrlCommand *)command{
    NSString *callbackId = command.callbackId;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPause:) name:@"OnPauseCDVStreamViewController" object:callbackId];
}

- (void)onPause:(NSNotification *)notification{
    NSString *callbackId = notification.object;
    
    if (callbackId != nil){
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [result setKeepCallbackAsBool:YES];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }
}

@end
