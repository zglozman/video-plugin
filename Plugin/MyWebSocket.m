#import "MyWebSocket.h"
#import "HTTPLogging.h"
#import "KFVideoFrame.h"
#import "NSDictionary+BVJSONString.h"



// Log levels: off, error, warn, info, verbose
// Other flags : trace
static const int httpLogLevel = HTTP_LOG_LEVEL_WARN | HTTP_LOG_FLAG_TRACE;


@implementation MyWebSocket

bool didSendInit = false;
bool sendingFeed = false;
int frameIndex = 0;

+(NSMutableArray*) sharedSocketsArray
{
    static NSMutableArray* theArray = nil;
    if (theArray == nil)
    {
        theArray = [[NSMutableArray alloc] init];
    }
    return theArray;
}


- (void)didOpen
{
	HTTPLogTrace();
    NSLog(@"FrameSocket: didOpen");
    
    [[MyWebSocket sharedSocketsArray] addObject:self];
        
    [super didOpen];
	
}

- (void)didReceiveMessage:(NSString *)msg
{
	NSLog(@"[%p]: didReceiveMessage: %@", self, msg);
	
    
    //Check and start stream or not

    
    NSArray *splitMessage = [msg componentsSeparatedByString:@" "];
    if (splitMessage.count > 0) {
        NSString *action = [splitMessage objectAtIndex:0];
        if ([action isEqualToString:@"REQUESTSTREAM"]) {
            NSLog(@"FrameSocket: didStartStream");

            sendingFeed = true;
        } else if ([action isEqualToString:@"STOPSTREAM"]) {
            NSLog(@"FrameSocket: didEndStream");

            sendingFeed = false;
        }
    }
    
    [super didReceiveMessage:msg];

}

- (void)didReceiveData:(NSData *)data {
    
    NSLog(@"Recivied binary data %lu", (unsigned long)data.length);
    
    [super didReceiveData:data];
    
}

- (void)didClose
{
    NSLog(@"FrameSocket: didClose");

    
    [[MyWebSocket sharedSocketsArray] removeObject:self];
    sendingFeed = false;
    didSendInit = false;
    
	HTTPLogTrace();
	
	[super didClose];
}

- (void)sendFrame:(KFVideoFrame*)frame withWidth:(NSUInteger)width andHeight:(NSUInteger)height {
    if (!didSendInit) {
        
        NSLog(@"FrameSocket: didSendInit");

        didSendInit = true;
        
        NSDictionary *initDictionary = @{@"action": @"init",
                                         @"width":[NSNumber numberWithInteger:width],
                                         @"height":[NSNumber numberWithInteger:height]};
        
        [self sendMessage:[initDictionary bv_jsonStringWithPrettyPrint:false]];
        
    }

    //Send if needed
    if (sendingFeed) {
//        if (frameIndex >= 999999 - 50) {
//            frameIndex = 0;
//        }
//        NSLog(@"FrameSocket: didSendFrame(%d)(%d)WithLength:%lu", frame.isKeyFrame, frameIndex, (unsigned long)frame.data.length);
        
        [self sendBinaryData:frame.data];
    }
    
}

@end
