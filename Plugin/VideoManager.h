//
//  VideoManager.h
//  VideoStreamer
//
//  Created by Artur Khidirnabiev on 07.11.15.
//  Copyright © 2015 arche. All rights reserved.
//

#ifndef __H_TEST_G_
#define __H_TEST_G_

#import <Foundation/Foundation.h>

@interface VideoManager : NSObject
- (BOOL)serverStatus;
- (void)startHttpServer;
@end

#endif
