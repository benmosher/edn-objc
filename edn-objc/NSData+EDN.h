//
//  NSData+EDN.h
//  edn-objc
//
//  Created by Ben Mosher on 9/2/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (EDN)

/**
 Returns full document, un-lazily, or nil if data is not valid EDN.
 Uses stock transmogrifiers + registered classes/categories.
 */
-(id)ednObject;

@end
