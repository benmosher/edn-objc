//
//  BMOEDNConsCell.h
//  edn-objc
//
//  Created by Ben Mosher on 8/25/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMOEDNConsCell : NSObject {
    @package
    id _first;
    id _rest;
}

@property (strong, nonatomic, readonly) id first;
@property (strong, nonatomic, readonly) id rest;

-(BOOL)isEqualToConsCell:(BMOEDNConsCell *)object;

@end

@interface BMOEDNList : NSObject<NSCopying, NSFastEnumeration> {
    NSUInteger _hash;
    @package
    BMOEDNConsCell * _head;
    dispatch_once_t _hashOnceToken;
    unsigned long _count; // for fast comparison and fast enumeration
}

@property (strong, nonatomic, readonly) BMOEDNConsCell *head;

-(BOOL)isEqualToList:(BMOEDNList *)list;

/**
 Returns a new list with the provided object
 as the new head.
 */
-(BMOEDNList *)push:(id)head;
/**
 Returns a new list with the rest object as
 the new head.
 */
-(BMOEDNList *)pop;

@end
