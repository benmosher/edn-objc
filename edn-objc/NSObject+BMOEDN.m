//
//  NSObject+BMOEDN.m
//  edn-objc
//
//  Created by Ben Mosher on 8/28/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "NSObject+BMOEDN.h"
#import "BMOEDNSerialization.h"

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
    objc_setAssociatedObject(self, @selector(EDNMetadata), EDNMetadata, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
