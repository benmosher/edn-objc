//
//  BMOEDNRegistry.h
//  edn-objc
//
//  Created by Ben Mosher on 8/30/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//
//  Register a class during load time (pre-`main` execution)
//  to ensure all de/serialization properly binds.

#import <Foundation/NSObjCRuntime.h>
@class BMOEDNSymbol;

/**
 Transmogrifiers can be registered to a tag or class at runtime
 to bind without a category (or re-bind to a class or tag with
 an existing or stock category).
 */
typedef id (^BMOEDNTransmogrifier)(id, NSError **);

/**
 Register a class that conforms to BMOEDNRepresentation. 
 Should be safe to call during +load. Will use
 the +ednTag symbol as the tag.
 If the provided class does not conform to BMOEDNRepresentation,
 the invocation is a no-op.
 Class registrations take priority over transmogrifiers.
 */
void BMOEDNRegisterClass(Class clazz);

/**
 Returns class object currently registered for given
 tag. Nil if tag is currently unregistered.
 */
Class BMOEDNRegisteredClassForTag(BMOEDNSymbol *tag);

