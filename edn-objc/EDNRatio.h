//
//  EDNRatio.h
//  edn-objc
//
//  Created by Ben Mosher on 7/10/14.
//  Copyright (c) 2014 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EDNRatio : NSNumber

+(instancetype) ratioWithNumerator:(int)numerator
                       denominator:(int)denominator;
-(instancetype) initWithNumerator:(int)numerator
                      denominator:(int)denominator;

@property (nonatomic, readonly) int numerator;
@property (nonatomic, readonly) int denominator;

@end
