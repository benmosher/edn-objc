//
//  BMOEDNReaderState.m
//  edn-objc
//
//  Created by Ben (home) on 9/2/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "BMOEDNReaderState.h"

@implementation BMOEDNReaderState

// "abstract" class

@end

@implementation BMOEDNDataReaderState

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

-(unichar)markedCharacter {
    return ((unichar)_chars[_markIndex]);
}

BOOL BMOOffsetInRange(NSUInteger loc, NSUInteger len, NSInteger offset) {
    // fancy comparison to ensure integer sign conversion does not occur unpredictably
    return (offset == 0 ||
            (offset > 0  && (len - loc) > (NSUInteger)offset) || // off the end
            (offset < 0 && loc >= (NSUInteger)(-1 * offset)));   // before the beginning
}

unichar BMOGetOffsetChar(char* array, NSUInteger length, NSUInteger index, NSInteger offset) {
    if (!BMOOffsetInRange(index, length, offset))
        return '\0';
    // any non-null comparisons should fail OR check for '\0' for out-of-range
    else return ((unichar)array[index+offset]);
}

/*-(void)moveMarkByOffset:(NSInteger)offset {
    if (!BMOOffsetInRange(_markIndex, _data.length, offset))
        @throw [NSException exceptionWithName:NSRangeException reason:@"Cannot move mark out of range of data." userInfo:nil];
    _markIndex += offset;
}*/

-(unichar)characterOffsetFromCurrent:(NSInteger)offset {
    return BMOGetOffsetChar(_chars, _data.length, _currentIndex, offset);
}
-(unichar)characterOffsetFromMark:(NSInteger)offset {
    return BMOGetOffsetChar(_chars, _data.length, _markIndex, offset);
}

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
