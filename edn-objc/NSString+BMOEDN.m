//
//  NSString+BMOEDN.m
//  edn-objc
//
//  Created by Ben Mosher on 8/26/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "NSString+BMOEDN.h"
#import "BMOEDNSerialization.h"
@implementation NSString (BMOEDN)

-(id)objectFromEDNString {
    return [BMOEDNSerialization EDNObjectWithData:[self dataUsingEncoding:NSUTF8StringEncoding] error:NULL];
}

@end
