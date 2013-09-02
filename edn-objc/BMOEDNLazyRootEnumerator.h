//
//  BMOEDNLazyRootEnumerator.h
//  edn-objc
//
//  Created by Ben (home) on 9/2/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Current enumeration index and last object provided for 
 convenience. First invocation is called with [0, nil].
 Should return nil on completion.
 
 TODO: futures. 
 */
typedef id (^BMOEDNLazy)(NSUInteger idx, id last);

@interface BMOEDNLazyEnumerator : NSEnumerator {
    __strong BMOEDNLazy _block;
    NSUInteger _currentIndex;
    id _lastObject;
}

-(instancetype)initWithBlock:(BMOEDNLazy)nextItemBlock;

@end
