//
//  BMOEDNRepresentation.h
//  edn-objc
//
//  Created by Ben Mosher on 8/29/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//
//  Defines a two-way street between EDN and an arbitrary obj-c class.

#import <Foundation/Foundation.h>
#import "BMOEDNError.h"
#import "BMOEDNSymbol.h"
#import "BMOEDNTaggedElement.h"
#import "BMOEDNRegistry.h" // imported for implementation convenience

@protocol BMOEDNRepresentation <NSObject>

/**
 Construct and return an immutable representation
 of the current object state.
 Behavior is undefined (and may include exceptions)
 if the returned tag does not match the implementation
 of +EDNTag.
 */
-(BMOEDNTaggedElement *)EDNRepresentation;

/**
 dispatch_once is your friend, here. Example implementation:
 
 +(BMOEDNSymbol *)EDNTag {
     static dispatch_once_t onceToken;
     static BMOEDNSymbol * tag;
     dispatch_once(&onceToken, ^{
         tag = [BMOEDNSymbol symbolWithNamespace:@"my" name:@"tag"];
     });
     return tag;
 }
 */
+(BMOEDNSymbol *)EDNTag;

/**
 Should return nil if tag is not a match or element contents
 are otherwise insufficient to create an instance.
 */
+(instancetype) objectWithEDNRepresentation:(BMOEDNTaggedElement *)taggedElement
                                      error:(NSError **)error;

@end
