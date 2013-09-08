//
//  NSInputStream+BMOEDN.m
//  edn-objc
//
//  Created by Ben Mosher on 9/2/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "NSInputStream+BMOEDN.h"
#import "BMOEDNSerialization.h"

@implementation NSInputStream (BMOEDN)

-(id)ednObject {
    return [BMOEDNSerialization ednObjectWithStream:self options:BMOEDNReadingLazyParsing|BMOEDNReadingMultipleObjects error:NULL];
}

@end
