//
//  BMOEDNCharacter.m
//  edn-objc
//
//  Created by Ben Mosher on 9/7/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "BMOEDNCharacter.h"

@implementation BMOEDNCharacter

-(instancetype)initWithUnichar:(unichar)unicharr {
    if (self = [super init]) {
        _unicharValue = unicharr;
    }
    return self;
}

+(instancetype)characterWithUnichar:(unichar)unicharr {
    return [[BMOEDNCharacter alloc] initWithUnichar:unicharr];
}

-(NSUInteger)hash {
    return (NSUInteger)_unicharValue;
}

-(BOOL)isEqual:(id)object {
    if (![object isMemberOfClass:[BMOEDNCharacter class]]) return false;
    return [self isEqualToCharacter:(BMOEDNCharacter *)object];
}

-(BOOL)isEqualToCharacter:(BMOEDNCharacter *)character {
    return (self->_unicharValue == character->_unicharValue);
}

@end
