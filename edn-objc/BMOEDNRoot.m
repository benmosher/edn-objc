//
//  BMOEDNRoot.m
//  edn-objc
//
//  Created by Ben Mosher on 8/31/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "BMOEDNRoot.h"

@implementation BMOEDNRoot

-(instancetype)initWithEnumerable:(id<NSObject,NSFastEnumeration>)elements {
    if (self = [super init]) {
        _elements = elements;
    }
    return self;
}

-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    return [_elements countByEnumeratingWithState:state objects:buffer count:len];
}

-(NSUInteger)hash {
    return [_elements hash];
}

-(BOOL)isEqual:(id)object {
    if (object == self) return true;
    if (object == nil) return false;
    if (![object isMemberOfClass:[BMOEDNRoot class]]) return false;
    return [_elements isEqual:((BMOEDNRoot *)object)->_elements];
}



@end
