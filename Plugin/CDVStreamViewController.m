//
//  ViewController.m
//  VideoStreamerCordovaPlugin
//
//  Created by Artur Khidirnabiev on 08.11.15.
//  Copyright © 2015 arche. All rights reserved.
//

#import "CDVStreamViewController.h"
#import "VideoManager.h"

#import "MyWebSocket.h"

@interface CDVStreamViewController ()
@property (nonatomic, strong) KFRecorder *recorder;
@end

@implementation CDVStreamViewController{
    AVCaptureVideoPreviewLayer* vieoPreview;
    BOOL isStarting;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

+ (KFRecorder *)getRecorder{
    static KFRecorder *recorder;
    
    if (recorder == nil){
        recorder = [[KFRecorder alloc] init];
    }
    
    return recorder;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeViewController:) name:@"CloseStreamController" object:nil];
    
    self.recorder = [[self class] getRecorder];
    
    self.recorder.delegate = self;
    [self.recorder startRecording];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

- (void)viewDidAppear:(BOOL)animated{
    self.recorder = [[self class] getRecorder];
    
    vieoPreview = self.recorder.previewLayer;
    [vieoPreview removeFromSuperlayer];
    vieoPreview.frame = self.preview.bounds;
    
    [self willRotateToInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation] duration:0];
    
    [self.preview.layer addSublayer:vieoPreview];
    
    [self updateLoadIndicator];
}

- (void)updateLoadIndicator{
    if (isStarting){
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
    if (!isStarting) {
        isStarting = YES;
        
        [sender setSelected:YES];
        
        [self startStream];
        
        //play
        [[NSNotificationCenter defaultCenter] postNotificationName:@"OnPauseCDVStreamViewController" object:nil];
    } else {
        isStarting = NO;
        [sender setSelected:NO];
        
        [self stopStream];
        
        //pause
        [[NSNotificationCenter defaultCenter] postNotificationName:@"OnStartCDVStreamViewController" object:nil];
    }
}

- (void)startStream{
    for (MyWebSocket *socket in [MyWebSocket sharedSocketsArray]){
        [socket startStream];
    }
}

- (void)stopStream{
    for (MyWebSocket *socket in [MyWebSocket sharedSocketsArray]){
        [socket stopStream];
    }
}

- (IBAction)closeViewController:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.manager.serverStatus){
            [self stopStream];
            
            [self.manager stopHttpServer:nil];
            
            if (isStarting){
                [self toggleRecording:self.recordButton];
            }
        } else {
            [self stopStream];
            
            if (isStarting){
                [self toggleRecording:self.recordButton];
            }
        }
        
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
