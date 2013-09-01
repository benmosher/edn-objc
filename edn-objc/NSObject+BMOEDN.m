//
//  NSObject+BMOEDN.m
//  edn-objc
//
//  Created by Ben Mosher on 8/28/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "NSObject+BMOEDN.h"
#import "BMOEDNSerialization.h"
#import "BMOEDNError.h"
#import <objc/runtime.h>

@implementation NSObject (BMOEDN)

-(NSData *)EDNData {
    return [BMOEDNSerialization dataWithEDNObject:self error:NULL];
}

-(NSString *)EDNString {
    return [BMOEDNSerialization stringWithEDNObject:self error:NULL];
}

-(NSDictionary *)EDNMetadata {
    return objc_getAssociatedObject(self, @selector(EDNMetadata));
}

-(void)setEDNMetadata:(NSDictionary *)EDNMetadata {
    
    if ([self isEqual:[NSNull null]]
        //|| [self isKindOfClass:[NSConstantString class]]
        || (__bridge CFBooleanRef)self == kCFBooleanTrue || (__bridge CFBooleanRef)self == kCFBooleanFalse) {
        @throw [NSException exceptionWithName:BMOEDNException reason:@"Metadata cannot be applied to static objects, such as [NSNull null], NSString literals, or edn booleans." userInfo:nil];
    }
    
    if ([EDNMetadata EDNMetadata] != nil) {
        @throw [NSException exceptionWithName:BMOEDNException reason:@"A metadata map must not, in turn, have associated metadata, nor _be_ associated as metadata." userInfo:nil];
    }
    
    // treat an empty assignment as a release.
    if (![EDNMetadata count]) EDNMetadata = nil;
    // associate the meta with the object
    objc_setAssociatedObject(self, @selector(EDNMetadata), EDNMetadata, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
