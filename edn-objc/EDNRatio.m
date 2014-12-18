//
//  EDNRatio.m
//  edn-objc
//
//  Created by Ben Mosher on 7/10/14.
//  Copyright (c) 2014 Ben Mosher. All rights reserved.
//

#import "EDNRatio.h"

@implementation EDNRatio

-(instancetype)initWithNumerator:(int)numerator
                     denominator:(int)denominator {
    if (self = [super init]) {
        _numerator = numerator;
        _denominator = denominator;
    }
    return self;
    
}

+(instancetype)ratioWithNumerator:(int)numerator denominator:(int)denominator {
    return [[EDNRatio alloc] initWithNumerator:numerator denominator:denominator];
}

-(const char *)objCType {
    return @encode(double);
}

-(double)doubleValue {
    double n, d;
    n = (double)_numerator;
    d = (double)_denominator;
    return (n/d);
}

-(NSString *)stringValue {
    return [NSString stringWithFormat:@"%d/%d", _numerator, _denominator];
}

@end
