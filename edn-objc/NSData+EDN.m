//
//  NSData+EDN.m
//  edn-objc
//
//  Created by Ben Mosher on 9/2/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "NSData+EDN.h"
#import "EDNSerialization.h"

@implementation NSData (EDN)

-(id)ednObject {
    return [EDNSerialization ednObjectWithData:self options:EDNReadingMultipleObjects error:NULL];
}

@end
