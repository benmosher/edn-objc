//
//  BMOEDNReaderState.m
//  edn-objc
//
//  Created by Ben Mosher on 9/2/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "BMOEDNReaderState.h"
#import "BMOEDNError.h"

@implementation BMOEDNDataReaderState

@synthesize error;

-(instancetype)initWithData:(NSData *)data {
    if (self = [super init]) {
        _data = data;
        _chars = (char *)[data bytes];	
        _currentIndex = 0;
        _markIndex = NSUIntegerMax;
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

-(void)clearMark {
    _markIndex = NSUIntegerMax;
}

-(NSUInteger)markedLength {
    return (_currentIndex > _markIndex)
    ? _currentIndex - _markIndex
    : 0;
}

-(NSMutableString *)markedString {
    if (_currentIndex < _markIndex) {
        return nil;
    }
    
    if (_currentIndex == _markIndex){
        return [@"" mutableCopy];
    }
    
    return [[NSMutableString alloc] initWithBytes:&_chars[_markIndex]
                                           length:(_currentIndex-_markIndex)
                                         encoding:NSUTF8StringEncoding];
}

@end

const static NSUInteger BufferLength = 16;
const static NSUInteger CharacterBufferLength = 4;

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
        _characterBuffer = (uint8_t *)malloc(CharacterBufferLength*sizeof(uint8_t));
    }
    return self;
}

-(void)dealloc {
    free(_buffer);
    free(_characterBuffer);
}

-(BOOL)isValid {
    return self.error == nil && (([_stream streamStatus] < NSStreamStatusAtEnd) || _currentBufferLength > 0);
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
    if (_currentBufferLength == 0) [self moveAhead]; // load the first char
    return _currentCharacter;
}

-(void)moveAhead {
    // append the last character, if needed
    if (_markBuffer && _characterBufferLength) {
        [_markBuffer appendBytes:_characterBuffer length:_characterBufferLength];
        _markBufferLength++;
    }
    
    // not thread safe, for the record.
    _characterBufferLength = 0;
    do {
        [self checkStreamAndBufferStatus];
        _characterBuffer[_characterBufferLength++] = _buffer[_currentBufferIndex++];
    } while (_characterBuffer[0] & 0x80
             && (_characterBuffer[0] & (0x80 >> _characterBufferLength))
             && _characterBufferLength < CharacterBufferLength);
    
    if (_characterBufferLength == 1) _currentCharacter = (unichar)_characterBuffer[0];
    else if (_characterBufferLength < 4) {
        _currentCharacter = 0;
        // get first byte bits
        uint8_t mask = (0x3F >> (_characterBufferLength - 2)); // first byte mask
        _currentCharacter |= ((unichar)(_characterBuffer[0] & mask)) << (6 * (_characterBufferLength - 1));
        for (int i = 1; i < _characterBufferLength; i++) {
            if (!(_characterBuffer[i] & 0x80)) {
                self.error = BMOEDNErrorMessage(BMOEDNErrorInvalidData, @"Invalid UTF8 encountered in stream.");
                return;
            }
            _currentCharacter |= ((unichar)(_characterBuffer[i] & 0x3F)) << (6 * (_characterBufferLength - i));
        }
    } else {
        self.error = BMOEDNErrorMessage(BMOEDNErrorInvalidData, @"Unable to parse Unicode points beyond U+FFFF at this time.");
    }
}

-(void)setMark {
    _markBuffer = [NSMutableData data];
    _markBufferLength = 0;
}

-(void)clearMark {
    _markBuffer = nil;
}

-(NSUInteger)markedLength {
    return _markBufferLength;
}

-(NSMutableString *)markedString {
    return [[NSMutableString alloc] initWithData:_markBuffer encoding:NSUTF8StringEncoding];
}

@end