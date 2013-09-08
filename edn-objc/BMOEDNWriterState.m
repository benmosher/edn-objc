//
//  BMOEDNWriterState.m
//  edn-objc
//
//  Created by Ben Mosher on 9/2/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "BMOEDNWriterState.h"

@implementation BMOEDNWriterState

-(instancetype)init {
    _exportable = YES;
    return [self initWithStream:[NSOutputStream outputStreamToMemory]];
}

- (instancetype)initWithStream:(NSOutputStream *)stream {
    if (self = [super init]) {
        _exported = 0;
        _stream = stream;
        [_stream open];
    }
    return self;
}

-(void)appendString:(NSString *)string {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    [self write:[data bytes] maxLength:[data length]];
}

-(void)write:(const uint8_t *)buffer maxLength:(NSUInteger)len {
    NSUInteger written = 0;
    do {
        written += [_stream write:buffer maxLength:(len-written)];
        if (_stream.streamError) {
            self.error = _stream.streamError;
            break;
        }
    } while (written < len);
}

-(NSData *)writtenData {
    dispatch_once(&_exported, ^{
        if (_exportable) {
            [_stream close];
            _data = [_stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
        }
    });
    return _data;
}



-(NSString *)writtenString {
    return [self writtenData]
        ? [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding]
        : nil;
}

@end
