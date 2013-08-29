//
//  NSObject+EDNData.m
//  edn-objc
//
//  Created by Ben Mosher on 8/28/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "NSObject+EDNData.h"
#import "BMOEDNSerialization.h"
@implementation NSObject (EDNData)

-(NSData *)ednData {
    return [BMOEDNSerialization dataWithEDNObject:self error:NULL];
}

-(NSString *)ednString {
    return [[NSString alloc] initWithData:[self ednData]
                                 encoding:NSUTF8StringEncoding];
}

@end
