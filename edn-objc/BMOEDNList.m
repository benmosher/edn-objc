//
//  BMOEDNConsCell.m
//  edn-objc
//
//  Created by Ben Mosher on 8/25/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "BMOEDNList.h"

@implementation BMOEDNConsCell

-(BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[BMOEDNConsCell class]]) return NO;
    return [self isEqualToConsCell:(BMOEDNConsCell *)object];
}

-(BOOL)isEqualToConsCell:(BMOEDNConsCell *)object {
    return [self.first isEqual:object.first]
        // direct comparison knocks out both nil or reference equality
        && ((self.rest == object.rest) || [self.rest isEqual:object.rest]);
}

-(NSUInteger)hash {
    return [self.first hash] ^ ([self.rest hash] * 17);
}

@end


// TODO: fast enumeration, recursive equality testing
// TODO: immutability + XOR'd hashes of cons cell contents? for set membership?
@implementation BMOEDNList

-(NSUInteger)hash {
    dispatch_once(&_hashOnceToken, ^{
        _hash = [self.head hash];
    });
    return _hash;
}

-(BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[BMOEDNList class]]) return NO;
    return [self isEqualToList:(BMOEDNList *)object];
}

-(BOOL)isEqualToList:(BMOEDNList *)list {
    return [self.head isEqualToConsCell:list.head];
}

-(id)copyWithZone:(NSZone *)zone {
    return self;
}

@end
