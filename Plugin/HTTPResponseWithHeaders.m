//
//  HTTPResponseWithHeaders.m
//  Kickflip
//
//  Created by Zeev Glozman on 10/30/15.
//  Copyright © 2015 Kickflip. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPResponeWithHeaders.h"

@implementation  HTTPResponeWithHeaders

- (NSDictionary *)httpHeaders
{
    NSString *key = @"Content-Type";
    NSString *value = @"text/xml";
    return [NSDictionary dictionaryWithObjectsAndKeys:value, key, nil];
}


@end