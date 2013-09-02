//
//  NSData+BMOEDN.h
//  edn-objc
//
//  Created by Ben (home) on 9/2/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (BMOEDN)

/**
 Returns full document, un-lazily, or nil if data is not valid EDN.
 Uses stock transmogrifiers + registered classes/categories.
 */
-(id)EDNObject;

@end
