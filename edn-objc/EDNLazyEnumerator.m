//
//  EDNLazyEnumerator.m
//  edn-objc
//
//  Created by Ben Mosher on 9/2/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "EDNLazyEnumerator.h"

@implementation EDNLazyEnumerator

-(instancetype)initWithBlock:(EDNLazy)nextItemBlock {
    if (self = [super init]) {
        _block = [nextItemBlock copy];
        _currentIndex = 0;
        _lastObject = nil;
    }
    return self;
}

-(id)nextObject {
    return _block(_currentIndex++,_lastObject);
}

-(NSArray *)allObjects {
    NSMutableArray *allObjs = [NSMutableArray new];
    id obj;
    while ((obj = [self nextObject])) {
        [allObjs addObject:obj];
    }
    return [allObjs copy];
}

@end
