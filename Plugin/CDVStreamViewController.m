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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeViewController:) name:@"CloseStreamController" object:nil];
    
    self.recorder = [[KFRecorder alloc] init];
    self.recorder.delegate = self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    vieoPreview = self.recorder.previewLayer;
    [vieoPreview removeFromSuperlayer];
    vieoPreview.frame = self.preview.bounds;
    
    [self willRotateToInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation] duration:0];
    
    [self.preview.layer addSublayer:vieoPreview];
}

- (void)viewDidAppear:(BOOL)animated{
    [self updateLoadIndicator];
}

- (void)updateLoadIndicator{
    if (self.recorder.isRecording){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.startIndicator stopAnimating];
        });
    }
}

- (void)startVideoStream{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.startIndicator setHidden:YES];
        
        [self toggleRecording:self.recordButton];
    });
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    if (vieoPreview.connection.supportsVideoOrientation) {
        vieoPreview.connection.videoOrientation = [self interfaceOrientationToVideoOrientation:toInterfaceOrientation];
    }
}

- (AVCaptureVideoOrientation)interfaceOrientationToVideoOrientation:(UIInterfaceOrientation)orientation {
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            [self.recorder setOrientation:@1];
            
            return AVCaptureVideoOrientationPortrait;
        case UIInterfaceOrientationPortraitUpsideDown:
            [self.recorder setOrientation:@4];
            
            return AVCaptureVideoOrientationPortraitUpsideDown;
        case UIInterfaceOrientationLandscapeLeft:
            [self.recorder setOrientation:@2];
            
            return AVCaptureVideoOrientationLandscapeLeft;
        case UIInterfaceOrientationLandscapeRight:
            [self.recorder setOrientation:@3];
            
            return AVCaptureVideoOrientationLandscapeRight;
        default:
            break;
    }
    
    return AVCaptureVideoOrientationPortrait;
}

- (IBAction)toggleRecording:(UIButton *)sender {
    if (!self.recorder.isRecording) {
        [sender setSelected:YES];
        
        [self.recorder startRecording];
        
        //play
        [[NSNotificationCenter defaultCenter] postNotificationName:@"OnPauseCDVStreamViewController" object:nil];
    } else {
        [sender setSelected:NO];
        
        [self.recorder stopRecording];
        
        //pause
        [[NSNotificationCenter defaultCenter] postNotificationName:@"OnStartCDVStreamViewController" object:nil];
    }
}

- (IBAction)closeViewController:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.manager.serverStatus){
            [self.manager stopHttpServer:nil];
            
            if (self.recorder.isRecording){
                [self toggleRecording:self.recordButton];
            }
        } else {
            if (self.recorder.isRecording){
                [self toggleRecording:self.recordButton];
            }
        }
        
        self.recorder = nil;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"OnCloseCDVStreamViewController" object:nil];
    }];
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
