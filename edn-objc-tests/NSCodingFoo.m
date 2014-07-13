//
//  NSCodingFoo.m
//  edn-objc
//
//  Created by Ben Mosher on 7/13/14.
//  Copyright (c) 2014 Ben Mosher. All rights reserved.
//

#import "NSCodingFoo.h"

@implementation NSCodingFoo

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:_a forKey:@"a"];
    [aCoder encodeObject:_b forKey:@"b"];
    [aCoder encodeObject:_bar forKey:@"bar"];
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _a = [aDecoder decodeIntegerForKey:@"a"];
        _b = [aDecoder decodeObjectForKey:@"b"];
        _bar = [aDecoder decodeObjectForKey:@"bar"];
    }
    return self;
}

-(BOOL)isEqual:(id)object {
    if (![object isMemberOfClass:[NSCodingFoo class]]) return false;
    return
        [object a] == _a &&
        [_b isEqualToString:[object b]] &&
        [_bar isEqual:[object bar]];
}

@end
