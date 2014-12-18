//
//  NSString+EDN.m
//  edn-objc
//
//  Created by Ben Mosher on 8/26/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "NSString+EDN.h"
#import "EDNSerialization.h"
@implementation NSString (EDN)

-(id)ednObject {
    return [EDNSerialization ednObjectWithData:[self dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
}

@end
