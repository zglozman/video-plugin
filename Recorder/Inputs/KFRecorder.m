//
//  KFRecorder.m
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "KFRecorder.h"
#import "KFAACEncoder.h"
#import "KFH264Encoder.h"
//#import "KFHLSMonitor.h"
#import "KFH264Encoder.h"
//#import "KFHLSWriter.h"
#import "KFLog.h"
//#import "KFAPIClient.h"
//#import "KFS3Stream.h"
#import "KFFrame.h"
#import "KFVideoFrame.h"
//#import "Kickflip.h"
#import "Endian.h"
#import "HttpConnectionHandler.h"
#import "MyWebSocket.h"
//#import <CocoaHTTPServer/HTTPServer.h>



@interface KFRecorder()
@property (nonatomic) double minBitrate;
@property (nonatomic) BOOL hasScreenshot;
@property KFVideoFrame *lastFrame;
@end

@implementation KFRecorder {
    }

dispatch_queue_t socketQ;


- (id) init {
    if (self = [super init]) {
        _minBitrate = 300 * 1000;
        [self setupSession];
        [self setupEncoders];
    }
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendLastFrame:) name:@"DIDSENDINIT" object:nil];
    
    static dispatch_once_t queueCreationGuard;
    dispatch_once(&queueCreationGuard, ^{
        socketQ = dispatch_queue_create("com.lfe.backgroundQueue.socket", 0);
    });
    
    return self;
}

- (void)sendLastFrame:(NSNotification *)notification{
    NSLog(@"Send Last Frame %@", self.lastFrame);
    
    MyWebSocket *socket = notification.object;
    
    [socket sendFrame:self.lastFrame withWidth:self.videoWidth andHeight:self.videoHeight];
}

- (AVCaptureDevice *)audioDevice
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    if ([devices count] > 0)
        return [devices objectAtIndex:0];
    
    return nil;
}

- (void) setupEncoders {
    self.audioSampleRate = 44100;
    self.videoHeight = 540;
    self.videoWidth = 960;
    int audioBitrate = 64 * 1000; // 64 Kbps
    int maxBitrate = 1000 * 1000; // 1000 mbps
    int videoBitrate = maxBitrate - audioBitrate;
    _h264Encoder = [[KFH264Encoder alloc] initWithBitrate:videoBitrate width:self.videoWidth height:self.videoHeight];
    _h264Encoder.delegate = self;
    
    _aacEncoder = [[KFAACEncoder alloc] initWithBitrate:audioBitrate sampleRate:self.audioSampleRate channels:1];
    _aacEncoder.delegate = self;
    _aacEncoder.addADTSHeader = YES;
}

- (void) setupAudioCapture {

    // create capture device with video input
    
    /*
     * Create audio connection
     */
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSError *error = nil;
    AVCaptureDeviceInput *audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:&error];
    if (error) {
        NSLog(@"Error getting audio input device: %@", error.description);
    }
    if ([_session canAddInput:audioInput]) {
        [_session addInput:audioInput];
    }
    
    _audioQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
    _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [_audioOutput setSampleBufferDelegate:self queue:_audioQueue];
    if ([_session canAddOutput:_audioOutput]) {
        [_session addOutput:_audioOutput];
    }
    _audioConnection = [_audioOutput connectionWithMediaType:AVMediaTypeAudio];
}

- (void) setupVideoCapture {
    [_session beginConfiguration];
    _session.sessionPreset = AVCaptureSessionPreset1280x720;
    [_session commitConfiguration];
    
    NSError *error = nil;
    AVCaptureDevice* videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if ([videoDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        NSError *error;
        [videoDevice lockForConfiguration:&error];
        [videoDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        [videoDevice unlockForConfiguration];
    }
    
    AVCaptureDeviceInput* videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (error) {
        NSLog(@"Error getting video input device: %@", error.description);
    }
    if ([_session canAddInput:videoInput]) {
        [_session addInput:videoInput];
    }
    
    // create an output for YUV output with self as delegate
    _videoQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_videoOutput setSampleBufferDelegate:self queue:_videoQueue];
    NSDictionary *captureSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    _videoOutput.videoSettings = captureSettings;
    _videoOutput.alwaysDiscardsLateVideoFrames = YES;
    if ([_session canAddOutput:_videoOutput]) {
        [_session addOutput:_videoOutput];
    }
    _videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    
    [self changeOrientationVideo];
}

#pragma mark KFEncoderDelegate method
- (void) encoder:(KFEncoder*)encoder encodedFrame:(KFFrame *)frame {
    if (encoder == _h264Encoder) {
        KFVideoFrame *videoFrame = (KFVideoFrame*)frame;
        dispatch_async(socketQ, ^{
            if(videoFrame.isKeyFrame){
                self.lastFrame = videoFrame;
                NSLog(@"Last frame is assigned ");
            }
            
            for (MyWebSocket *socket in [MyWebSocket sharedSocketsArray]) {
                [socket sendFrame:videoFrame withWidth:self.videoWidth andHeight:self.videoHeight];
            }
        });
       // NSLog(@"Recivied frame %d %d", frame.data.length, videoFrame.isKeyFrame);
//        [_hlsWriter processEncodedData:videoFrame.data presentationTimestamp:videoFrame.pts streamIndex:0 isKeyFrame:videoFrame.isKeyFrame];
    }
//    else if (encoder == _aacEncoder) {
//        [_hlsWriter processEncodedData:frame.data presentationTimestamp:frame.pts streamIndex:1 isKeyFrame:NO];
//    }
}

#pragma mark AVCaptureOutputDelegate method
- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (!_isRecording) {
        return;
    }
    // pass frame to encoders
    if (connection == _videoConnection) {
        if (!_hasScreenshot) {
            UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
            NSString *path = [basePath stringByAppendingPathComponent:@"thumb.jpg"];
            NSData *imageData = UIImageJPEGRepresentation(image, 0.7);
            [imageData writeToFile:path atomically:NO];
            _hasScreenshot = YES;
        }
        [_h264Encoder encodeSampleBuffer:sampleBuffer];
    } else if (connection == _audioConnection) {
        [_aacEncoder encodeSampleBuffer:sampleBuffer];
    }
}

// Create a UIImage from sample buffer data
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}

- (void) setupSession {
    _session = [[AVCaptureSession alloc] init];
    [self setupVideoCapture];
    [self setupAudioCapture];
    
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
}

- (void) startRecording {
    
    
    // start capture and a preview layer
    [_session startRunning];
    
    self.isRecording = YES;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(recorderDidStartRecording:error:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate recorderDidStartRecording:self error:nil];
        });
    }
    
}

- (void) stopRecording {
    [_session stopRunning];
    self.isRecording = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(recorderDidFinishRecording:error:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate recorderDidFinishRecording:self error:nil];
        });
    }
}

- (void)changeOrientationVideo{
    AVCaptureVideoOrientation orientation;
    
    switch ([self.orientation integerValue]) {
        case 0:
            orientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case 1:
            orientation = AVCaptureVideoOrientationPortrait;
            break;
        case 2:
            orientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case 3:
            orientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        case 4:
            orientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        default:
            orientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
    }
    
    if ([_videoConnection isVideoOrientationSupported]) {
        [_videoConnection setVideoOrientation:orientation];
    }
}

- (void)setOrientation:(NSNumber *)orientation{
    _orientation = orientation;
    
    [self changeOrientationVideo];
}

@end
