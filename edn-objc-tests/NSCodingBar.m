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
    // NOOP ATM
    return nil;
}

@end
