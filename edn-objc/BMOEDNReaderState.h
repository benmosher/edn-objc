//
//  BMOEDNReaderState.h
//  edn-objc
//
//  Created by Ben (home) on 9/2/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>

// TODO: profile, see if struct+functions are faster
@protocol BMOEDNReaderState <NSObject>

@property (nonatomic, readonly, getter = isValid) BOOL valid;
/**
 Caller should check isValid first; if parser is not
 in a valid state, behavior is undefined.
 */
@property (nonatomic, readonly) unichar currentCharacter;
@property (nonatomic, readonly) unichar markedCharacter;
/**
 @return '\0' if out of range
 */
-(unichar)characterOffsetFromMark:(NSInteger)offset;
/**
 @return '\0' if out of range
 */
-(unichar)characterOffsetFromCurrent:(NSInteger)offset;

@property (strong, nonatomic) NSError * error;

-(void) moveAhead;
/**
 @throws NSRangeException if mark would be placed outside data
 */
//-(void) moveMarkByOffset:(NSInteger)offset;
/**
 Set mark to current parser index.
 */
-(void) setMark;
-(NSUInteger) markedLength;
-(NSMutableString *) markedString;

@end

@interface BMOEDNDataReaderState : NSObject <BMOEDNReaderState> {
    NSUInteger _currentIndex;
    NSUInteger _markIndex;
    char *_chars;
    __strong NSData * _data;
}


-(instancetype)initWithData:(NSData *)data;

@end

