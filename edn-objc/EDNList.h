//
//  EDNList.h
//  edn-objc
//
//  Created by Ben Mosher on 8/25/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EDNConsCell : NSObject {
    @package
    id _first;
    id _rest;
}

@property (strong, nonatomic, readonly) id first;
@property (strong, nonatomic, readonly) id rest;

-(BOOL)isEqualToConsCell:(EDNConsCell *)object;

@end

@interface EDNList : NSObject<NSCopying, NSFastEnumeration> {
    NSUInteger _hash;
    @package
    BOOL _hashed;
    EDNConsCell * _head;
    unsigned long _count; // for fast comparison and fast enumeration
}

@property (strong, nonatomic, readonly) EDNConsCell *head;

-(BOOL)isEqualToList:(EDNList *)list;

/**
 Returns a new list with the provided object
 as the new head.
 */
-(EDNList *)listByPushing:(id)head;
/**
 Returns a new list with the rest object as
 the new head.
 */
-(EDNList *)listByPopping;

@end
