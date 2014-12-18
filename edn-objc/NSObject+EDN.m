//
//  NSObject+EDN.m
//  edn-objc
//
//  Created by Ben Mosher on 8/28/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "NSObject+EDN.h"
#import "EDNSerialization.h"
#import "EDNError.h"
#import <objc/runtime.h>

@implementation NSObject (EDN)

-(NSData *)ednData {
    return [EDNSerialization dataWithEdnObject:self error:NULL];
}

-(NSString *)ednString {
    return [EDNSerialization stringWithEdnObject:self error:NULL];
}

-(NSDictionary *)ednMetadata {
    return objc_getAssociatedObject(self, @selector(ednMetadata));
}

-(void)setEdnMetadata:(NSDictionary *)ednMetadata {
    
    if ([self isEqual:[NSNull null]]
        //|| [self isKindOfClass:[NSConstantString class]]
        || (__bridge CFBooleanRef)self == kCFBooleanTrue || (__bridge CFBooleanRef)self == kCFBooleanFalse) {
        @throw [NSException exceptionWithName:EDNException reason:@"Metadata cannot be applied to static objects, such as [NSNull null], NSString literals, or edn booleans." userInfo:nil];
    }
    
    if ([ednMetadata ednMetadata] != nil) {
        @throw [NSException exceptionWithName:EDNException reason:@"A metadata map must not, in turn, have associated metadata, nor _be_ associated as metadata." userInfo:nil];
    }
    
    // treat an empty assignment as a release.
    if (![ednMetadata count]) ednMetadata = nil;
    // associate the meta with the object
    objc_setAssociatedObject(self, @selector(ednMetadata), ednMetadata, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
