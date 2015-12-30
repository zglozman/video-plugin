#import "MyWebSocket.h"
#import "HTTPLogging.h"
#import "KFVideoFrame.h"
#import "NSDictionary+BVJSONString.h"



// Log levels: off, error, warn, info, verbose
// Other flags : trace
static const int httpLogLevel = HTTP_LOG_LEVEL_WARN | HTTP_LOG_FLAG_TRACE;


@interface MyWebSocket ()
@property BOOL didReceiveRequest;
@end

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

- (void)stopStream{
    sendingFeed = false;
    didSendInit = false;
}

- (void)startStream{
    sendingFeed = true;
}

- (void)didOpen
{
    HTTPLogTrace();
    NSLog(@"FrameSocket: didOpen");
    
    static NSLock *lock;
    
    if (lock != nil){
        lock = [[NSLock alloc] init];
    }
    
    [lock lock];
    [[MyWebSocket sharedSocketsArray] addObject:self];
    [lock unlock];
    
    didSendInit = false;
    
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
    
    static NSLock *lock;
    
    if (lock != nil){
        lock = [[NSLock alloc] init];
    }
    
    [lock lock];
    [[MyWebSocket sharedSocketsArray] removeObject:self];
    sendingFeed = false;
    didSendInit = false;
    [lock unlock];
    
    HTTPLogTrace();
    
    [super didClose];
}

- (void)sendFrame:(KFVideoFrame*)frame withWidth:(NSUInteger)width andHeight:(NSUInteger)height {
    if (sendingFeed == true){
        if(didSendInit == false) {
            NSLog(@"FrameSocket: didSendInit");
            
            didSendInit = true;
            
            NSDictionary *initDictionary = @{@"action": @"init",
                                             @"width":[NSNumber numberWithInteger:width],
                                             @"height":[NSNumber numberWithInteger:height]};
            
            [self sendMessage:[initDictionary bv_jsonStringWithPrettyPrint:false]];
        }
        
        [self sendBinaryData:frame.data];
    }
}

- (void)dealloc{
    NSLog(@"MyWebSocket Dealloc");
}

@end
