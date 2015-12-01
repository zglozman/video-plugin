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

@interface CDVStreamViewController : UIViewController<KFRecorderDelegate>
@property (nonatomic, strong) KFRecorder *recorder;
@property VideoManager *manager;
@property (weak, nonatomic) IBOutlet UIView *preview;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *startIndicator;

- (IBAction)closeViewController:(id)sender;
- (IBAction)toggleRecording:(id)sender;

- (void)startVideoStream;
@end

