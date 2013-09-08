//
//  BMOEDNCoder.m
//  edn-objc
//
//  Created by Ben Mosher on 9/7/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "BMOEDNCoder.h"

@implementation BMOEDNArchiver

-(BOOL)allowsKeyedCoding {
    return YES;
}

-(void)encodeValueOfObjCType:(const char *)type at:(const void *)addr {
    
}

@end
