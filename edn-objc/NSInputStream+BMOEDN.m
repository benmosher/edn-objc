//
//  NSInputStream+BMOEDN.m
//  edn-objc
//
//  Created by Ben (home) on 9/2/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "NSInputStream+BMOEDN.h"
#import "BMOEDNSerialization.h"

@implementation NSInputStream (BMOEDN)

-(id)EDNObject {
    return [BMOEDNSerialization EDNObjectWithStream:self options:BMOEDNReadingMultipleObjects|BMOEDNReadingLazyParsing error:NULL];
}

@end
