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
    // NOOP ATM
    return nil;
}

@end
