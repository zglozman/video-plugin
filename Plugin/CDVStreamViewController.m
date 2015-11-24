//
//  ViewController.m
//  VideoStreamerCordovaPlugin
//
//  Created by Artur Khidirnabiev on 08.11.15.
//  Copyright © 2015 arche. All rights reserved.
//

#import "CDVStreamViewController.h"
#import "VideoManager.h"


@interface CDVStreamViewController ()
@end

@implementation CDVStreamViewController{
    AVCaptureVideoPreviewLayer* vieoPreview;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.recorder = [[KFRecorder alloc] init];
    self.recorder.delegate = self;
    
    [self.recorder startRecording];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    vieoPreview = self.recorder.previewLayer;
    [vieoPreview removeFromSuperlayer];
    vieoPreview.frame = self.preview.bounds;
    
    [self willRotateToInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation] duration:0];
    
    [self.preview.layer addSublayer:vieoPreview];
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    if (vieoPreview.connection.supportsVideoOrientation) {
        vieoPreview.connection.videoOrientation = [self interfaceOrientationToVideoOrientation:toInterfaceOrientation];
    }
}

- (AVCaptureVideoOrientation)interfaceOrientationToVideoOrientation:(UIInterfaceOrientation)orientation {
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;
        case UIInterfaceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
        case UIInterfaceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeLeft;
        case UIInterfaceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeRight;
        default:
            break;
    }
    
    return AVCaptureVideoOrientationPortrait;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)toggleRecording:(UIButton *)sender {
    if (!self.recorder.isRecording) {
        [sender setTitle:@"Recording" forState:UIControlStateNormal];
        [self.recorder startRecording];
    } else {
        [sender setTitle:@"Not recording" forState:UIControlStateNormal];
        [self.recorder stopRecording];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void) recorderDidStartRecording:(KFRecorder *)recorder error:(NSError *)error {
    if (error) {
        NSLog(@"Error starting stream: %@", error.userInfo);
        NSDictionary *response = [error.userInfo objectForKey:@"response"];
        NSString *reason = nil;
        if (response) {
            reason = [response objectForKey:@"reason"];
        }
        NSMutableString *errorMsg = [NSMutableString stringWithFormat:@"Error starting stream: %@.", error.localizedDescription];
        if (reason) {
            [errorMsg appendFormat:@" %@", reason];
        }
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Stream Start Error" message:errorMsg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
    }
}

- (void) recorder:(KFRecorder *)recorder streamReadyAtURL:(NSURL *)url {
}

- (void) recorderDidFinishRecording:(KFRecorder *)recorder error:(NSError *)error {
}

@end
