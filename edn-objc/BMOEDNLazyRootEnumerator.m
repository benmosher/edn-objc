//
//  BMOEDNLazyRootEnumerator.m
//  edn-objc
//
//  Created by Ben (home) on 9/2/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "BMOEDNLazyRootEnumerator.h"

@implementation BMOEDNLazyEnumerator

-(instancetype)initWithBlock:(BMOEDNLazy)nextItemBlock {
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
