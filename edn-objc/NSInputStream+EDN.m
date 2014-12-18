//
//  NSInputStream+EDN.m
//  edn-objc
//
//  Created by Ben Mosher on 9/2/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "NSInputStream+EDN.h"
#import "EDNSerialization.h"

@implementation NSInputStream (EDN)

-(id)ednObject {
    return [EDNSerialization ednObjectWithStream:self options:EDNReadingLazyParsing|EDNReadingMultipleObjects error:NULL];
}

@end
