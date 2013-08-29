//
//  NSString+EDNObject.m
//  edn-objc
//
//  Created by Ben Mosher on 8/26/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "NSString+EDNObject.h"
#import "BMOEDNSerialization.h"
@implementation NSString (EDNObject)

-(id)ednObject {
    return [BMOEDNSerialization EDNObjectWithData:[self dataUsingEncoding:NSUTF8StringEncoding] error:NULL];
}

@end
