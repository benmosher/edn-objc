//
//  NSObject+BMOEDN.h
//  edn-objc
//
//  Created by Ben Mosher on 8/28/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (BMOEDN)

- (NSData *)ednData;
- (NSString *)ednString;

@property (copy, nonatomic) NSDictionary * ednMetadata;

@end
