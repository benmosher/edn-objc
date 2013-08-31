//
//  NSObject+BMOEDN.m
//  edn-objc
//
//  Created by Ben Mosher on 8/28/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "NSObject+BMOEDN.h"
#import "BMOEDNSerialization.h"
@implementation NSObject (BMOEDN)

-(NSData *)EDNData {
    return [BMOEDNSerialization dataWithEDNObject:self error:NULL];
}

-(NSString *)EDNString {
    return [BMOEDNSerialization stringWithEDNObject:self error:NULL];
}

@end
