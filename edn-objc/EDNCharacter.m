//
//  EDNCharacter.m
//  edn-objc
//
//  Created by Ben Mosher on 9/7/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "EDNCharacter.h"

@implementation EDNCharacter

-(instancetype)initWithUnichar:(unichar)unicharr {
    if (self = [super init]) {
        _unicharValue = unicharr;
    }
    return self;
}

+(instancetype)characterWithUnichar:(unichar)unicharr {
    return [[EDNCharacter alloc] initWithUnichar:unicharr];
}

-(NSUInteger)hash {
    return (NSUInteger)_unicharValue;
}

-(BOOL)isEqual:(id)object {
    if (![object isMemberOfClass:[EDNCharacter class]]) return false;
    return [self isEqualToCharacter:(EDNCharacter *)object];
}

-(BOOL)isEqualToCharacter:(EDNCharacter *)character {
    return (self->_unicharValue == character->_unicharValue);
}

@end
