//
//  ViewController.h
//  VideoStreamerCordovaPlugin
//
//  Created by Artur Khidirnabiev on 08.11.15.
//  Copyright © 2015 arche. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KFRecorder.h"
#import "VideoManager.h"

@class VideoManager;

@interface CDVStreamViewController : UIViewController<KFRecorderDelegate>
@property (weak, nonatomic) VideoManager *manager;
@property (weak, nonatomic) IBOutlet UIView *preview;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *startIndicator;

@property (nonatomic,strong) void (^closeCallback)();

- (void)closeController;

- (IBAction)closeViewController:(id)sender;
- (IBAction)toggleRecording:(id)sender;

- (void)startVideoStream;

- (void)sleep;
- (void)unsleep;

@end

