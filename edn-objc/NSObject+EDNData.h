//
//  NSObject+EDNData.h
//  edn-objc
//
//  Created by Ben Mosher on 8/28/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (EDNData)

- (NSData *)ednData;

- (NSString *)ednString;

@end
