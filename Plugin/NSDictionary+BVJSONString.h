//
//  NSDictionary+BVJSONString.h
//  Pods
//
//  Created by Zeev Glozman on 10/31/15.
//
//

#import <Foundation/Foundation.h>

@interface NSDictionary (BVJSONString)

-(NSString*) bv_jsonStringWithPrettyPrint:(BOOL) prettyPrint;

@end
