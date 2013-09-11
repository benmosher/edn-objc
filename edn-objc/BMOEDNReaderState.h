//
//  BMOEDNReaderState.h
//  edn-objc
//
//  Created by Ben Mosher on 9/2/13.
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

@property (strong, nonatomic) NSError * error;

-(void) moveAhead;

/**
 Set mark to current parser index.
 */
-(void) setMark;
-(NSUInteger) markedLength;
-(NSMutableString *) markedString;
-(void) clearMark;

@end

@interface BMOEDNDataReaderState : NSObject <BMOEDNReaderState> {
    NSUInteger _currentIndex;
    NSUInteger _markIndex;
    char *_chars;
    __strong NSData * _data;
}

-(instancetype)initWithData:(NSData *)data;

@end

@interface BMOEDNStreamReaderState : NSObject <BMOEDNReaderState> {
    __strong NSInputStream *_stream;
    
    __strong NSMutableData *_markBuffer;
    NSUInteger _markBufferLength; // in characters, not bytes
    
    uint8_t *_buffer;
    NSInteger _currentBufferLength;
    NSInteger _currentBufferIndex;
    
    unichar _currentCharacter;
    uint8_t *_characterBuffer;
    uint8_t _characterBufferLength;
}

-(instancetype)initWithStream:(NSInputStream *)stream;

@end
