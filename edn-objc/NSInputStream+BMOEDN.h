//
//  NSInputStream+BMOEDN.h
//  edn-objc
//
//  Created by Ben (home) on 9/2/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSInputStream (BMOEDN)

/**
 Returns a lazy EDN object for all objects, with stock transmogrifiers.
 */
-(id)EDNObject;

@end
