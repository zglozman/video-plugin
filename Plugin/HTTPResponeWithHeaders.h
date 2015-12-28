//
//  HTTPResponeWithHeaders.h
//  Kickflip
//
//  Created by Zeev Glozman on 10/30/15.
//  Copyright © 2015 Kickflip. All rights reserved.
//

#import "HTTPServer.h"
#import "HTTPDataResponse.h"


@interface 	HTTPResponeWithHeaders :  HTTPDataResponse
- (void)setAllowOrigin:(BOOL)state;
@end

