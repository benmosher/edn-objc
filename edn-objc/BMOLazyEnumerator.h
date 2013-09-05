//
//  BMOLazyEnumerator.h
//  edn-objc
//
//  Created by Ben Mosher on 9/2/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Current enumeration index and last object provided for 
 convenience. First invocation is called with [0, nil].
 Should return nil on completion.
 
 TODO: futures. 
 */
typedef id (^BMOLazy)(NSUInteger idx, id last);

@interface BMOLazyEnumerator : NSEnumerator {
    __strong BMOLazy _block;
    NSUInteger _currentIndex;
    id _lastObject;
}

-(instancetype)initWithBlock:(BMOLazy)nextItemBlock;

@end
