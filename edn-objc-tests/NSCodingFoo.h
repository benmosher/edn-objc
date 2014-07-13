//
//  NSCodingFoo.h
//  edn-objc
//
//  Created by Ben Mosher on 7/13/14.
//  Copyright (c) 2014 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSCodingBar.h"

@interface NSCodingFoo : NSObject <NSCoding>

@property (nonatomic) NSInteger a;
@property (strong, nonatomic) NSString *b;
@property (strong, nonatomic) NSCodingBar *bar;


@end
