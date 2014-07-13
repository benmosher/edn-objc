//
//  NSCodingBar.h
//  edn-objc
//
//  Created by Ben Mosher on 7/13/14.
//  Copyright (c) 2014 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSCodingBar : NSObject <NSCoding>

@property (strong, nonatomic) NSArray *array;
@property (strong, nonatomic) NSDictionary *dict;

@end
