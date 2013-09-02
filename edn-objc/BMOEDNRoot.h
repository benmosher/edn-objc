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

@interface BMOEDNRoot : NSObject<NSFastEnumeration> {
    id<NSObject,NSFastEnumeration> _elements;
}

-(instancetype)initWithEnumerable:(id<NSObject,NSFastEnumeration>)elements;

@end

