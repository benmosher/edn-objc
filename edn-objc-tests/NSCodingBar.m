//
//  NSCodingBar.m
//  edn-objc
//
//  Created by Ben Mosher on 7/13/14.
//  Copyright (c) 2014 Ben Mosher. All rights reserved.
//

#import "NSCodingBar.h"

@implementation NSCodingBar

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_array forKey:@"array"];
    [aCoder encodeObject:_dict forKey:@"dict"];
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]){
        _array = [aDecoder decodeObjectForKey:@"array"];
        _dict = [aDecoder decodeObjectForKey:@"dict"];
    }
    return self;
}

-(BOOL)isEqual:(id)object {
    if (![object isMemberOfClass:[NSCodingBar class]]) return false;
    return
        (_array == [object array] || [_array isEqual:[object array]]) &&
        (_dict == [object dict] || [_dict isEqual:[object dict]]);
}

@end
