//
//  BMOEDNRoot.h
//  edn-objc
//
//  Created by Ben Mosher on 8/31/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//
//  Supports round-trip serialization of multiple objects without a single
//  top-level root object (such as a Clojure source file).
//
//  Must not be present anywhere but at the root of an edn object graph.

#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
/**
 If the underlying element collection is not an NSArray, it will be
 copied into a buffer as it is enumerator. 
 */
@interface BMOEDNRoot : NSObject<NSFastEnumeration> {
    id<NSObject,NSFastEnumeration> _elements;
    NSMutableArray *_realized; // TODO: use this sucker
    dispatch_queue_t _realizationQueue;
    unsigned long mutationMarker;
}

-(instancetype)initWithEnumerable:(id<NSObject,NSFastEnumeration>)elements;

/**
 Use this guy (vs. fast enumeration) for one-by-one laziness.
 */
//-(NSEnumerator *) objectEnumerator;

@end

