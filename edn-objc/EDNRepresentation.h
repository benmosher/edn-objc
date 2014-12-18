//
//  EDNRepresentation.h
//  edn-objc
//
//  Created by Ben Mosher on 8/29/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//
//  Defines a two-way street between EDN and an arbitrary obj-c class.

#import <Foundation/Foundation.h>
#import "EDNError.h"
#import "EDNSymbol.h"
#import "EDNTaggedElement.h"
#import "EDNRegistry.h" // imported for implementation convenience

@protocol EDNRepresentation <NSObject>

/**
 Construct and return an immutable representation
 of the current object state.
 Behavior is undefined (and may include exceptions)
 if the returned tag does not match the implementation
 of +ednTag.
 */
-(EDNTaggedElement *)ednRepresentation;

/**
 dispatch_once is your friend, here. Example implementation:
 
 +(EDNSymbol *)ednTag {
     static dispatch_once_t onceToken;
     static EDNSymbol * tag;
     dispatch_once(&onceToken, ^{
         tag = [EDNSymbol symbolWithNamespace:@"my" name:@"tag"];
     });
     return tag;
 }
 */
+(EDNSymbol *)ednTag;

/**
 Should return nil if tag is not a match or element contents
 are otherwise insufficient to create an instance.
 */
+(instancetype) objectWithEdnRepresentation:(EDNTaggedElement *)taggedElement
                                      error:(NSError **)error;

@end
