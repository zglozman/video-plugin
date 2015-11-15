#import <Foundation/Foundation.h>
#import "HTTPServer.h"
#import "WebSocket.h"

@class KFVideoFrame;

@interface MyWebSocket : WebSocket
{
	
}

+(NSMutableArray*) sharedSocketsArray;

- (void)sendFrame:(KFVideoFrame*)frame withWidth:(NSUInteger)width andHeight:(NSUInteger)height;


@end
