//
//  BMOEDNReaderState.m
//  edn-objc
//
//  Created by Ben (home) on 9/2/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "BMOEDNReaderState.h"


@implementation BMOEDNDataReaderState

@synthesize error;

-(instancetype)initWithData:(NSData *)data {
    if (self = [super init]) {
        _data = data;
        _chars = (char *)[data bytes];	
        _currentIndex = 0;
    }
    return self;
}

-(BOOL)isValid {
    return (self.error == nil && _currentIndex < _data.length);
}

-(unichar)currentCharacter {
    return ((unichar)_chars[_currentIndex]);
};

-(void)moveAhead {
    _currentIndex++;
}

-(void)setMark {
    _markIndex = _currentIndex;
}

-(NSUInteger)markedLength {
    return (_currentIndex > _markIndex)
    ? _currentIndex - _markIndex
    : 0;
}

-(NSMutableString *)markedString {
    if (_currentIndex == _markIndex){
        return [@"" mutableCopy];
    }
    return [[NSMutableString alloc] initWithBytes:&_chars[_markIndex]
                                           length:(_currentIndex-_markIndex)
                                         encoding:NSUTF8StringEncoding];
}

@end

const static NSUInteger BufferLength = 16;

@interface BMOEDNStreamReaderState ()

-(void)checkStreamAndBufferStatus;

@end

@implementation BMOEDNStreamReaderState

@synthesize error;

-(instancetype)initWithStream:(NSInputStream *)stream {
    if (self = [super init]) {
        _stream = stream;
        _buffer = (uint8_t *)malloc(BufferLength*sizeof(uint8_t));
        _currentBufferIndex = 0;
        _currentBufferLength = 0;
    }
    return self;
}

-(void)dealloc {
    free(_buffer);
}

-(BOOL)isValid {
    return self.error == nil && ([_stream streamStatus] < NSStreamStatusAtEnd);
}

-(void)checkStreamAndBufferStatus {
    if ([_stream streamStatus] == NSStreamStatusNotOpen)
        [_stream open];
    while (_currentBufferIndex >= _currentBufferLength) {
        _currentBufferIndex -= _currentBufferLength;
        _currentBufferLength = [_stream read:_buffer maxLength:BufferLength];
        if (_currentBufferLength <= 0) break; // error from NSStream
    }
}

-(unichar)currentCharacter {
    [self checkStreamAndBufferStatus];
    return (unichar)_buffer[_currentBufferIndex];
}

-(void)moveAhead {
    if (_markBuffer) {
        [self checkStreamAndBufferStatus];
        [_markBuffer appendBytes:(_buffer+_currentBufferIndex) length:1];
    }
    _currentBufferIndex++;
}

-(void)setMark {
    _markBuffer = [NSMutableData data];
}

-(NSUInteger)markedLength {
    return [_markBuffer length];
}

-(NSMutableString *)markedString {
    return [[NSMutableString alloc] initWithData:_markBuffer encoding:NSUTF8StringEncoding];
}

@end