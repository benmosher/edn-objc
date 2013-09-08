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
 copied into a buffer as it is enumerated. 
 */
@interface BMOEDNRoot : NSObject<NSFastEnumeration> {
    NSEnumerator * _enumerator;
    NSArray *_realized;
    dispatch_queue_t _realizationQueue;
    unsigned long mutationMarker;
}

-(instancetype)initWithEnumerator:(NSEnumerator *)enumerator;
-(instancetype)initWithArray:(NSArray *)array;

/**
 Array-style index and subscripting support.
 */
-(id)objectAtIndex:(NSUInteger)idx;
-(id)objectAtIndexedSubscript:(NSUInteger)idx;

/**
 Use this guy (vs. fast enumeration) for one-by-one laziness.
 Also: he is thread safe for multiple consumers; i.e. you can
 pass one instance of this enumerator to multiple consumers and
 each deserialized EDN object will be delivered to one (and only
 one) consumer, if all consumers call only -nextObject.
 
 Calls to -allObjects will snapshot the remainder and fully
 realize the root. As such, they will block the caller until
 the underlying enumerator is exhausted.
 */
-(NSEnumerator *) objectEnumerator;

@end

