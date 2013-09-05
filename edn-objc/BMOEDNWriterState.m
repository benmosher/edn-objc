//
//  BMOEDNWriterState.m
//  edn-objc
//
//  Created by Ben Mosher on 9/2/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "BMOEDNWriterState.h"

@implementation BMOEDNWriterState

-(instancetype)init{
    if (self = [super init]) {
        _mutableString = [NSMutableString new];
        _currentIndex = 0;
    }
    return self;
}

-(void)appendString:(NSString *)string {
    [_mutableString appendString:string];
}

-(NSData *)writtenData {
    return [_mutableString dataUsingEncoding:NSUTF8StringEncoding];
}

-(NSString *)writtenString {
    return [_mutableString copy];
}

@end
