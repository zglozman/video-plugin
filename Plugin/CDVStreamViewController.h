//
//  ViewController.h
//  VideoStreamerCordovaPlugin
//
//  Created by Artur Khidirnabiev on 08.11.15.
//  Copyright © 2015 arche. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KFRecorder.h"

@interface CDVStreamViewController : UIViewController<KFRecorderDelegate>
@property (nonatomic, strong) KFRecorder *recorder;
@property (weak, nonatomic) IBOutlet UIView *preview;
@property (weak, nonatomic) IBOutlet UIView *splash;

- (IBAction)toggleRecording:(id)sender;
- (IBAction)alertClose:(id)sender;
@end

