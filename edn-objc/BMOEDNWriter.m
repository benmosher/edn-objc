//
//  BMOEDNWriter.m
//  edn-objc
//
//  Created by Ben Mosher on 8/28/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "BMOEDNWriter.h"
#import "BMOEDNDefines.pch"

// TODO: struct + functions

@interface BMOEDNWriterState : NSObject {
    NSUInteger _currentIndex;
    NSMutableData *_data;
}
@property (strong, nonatomic) NSError *error;

-(instancetype)initWithMutableData:(NSMutableData *)data;

-(void)appendCharacter:(unichar)character;
-(void)appendData:(NSData *)data;
-(void)appendBytes:(const void *)bytes length:(NSUInteger)length;
@end

@implementation BMOEDNWriterState

-(instancetype)initWithMutableData:(NSMutableData *)data {
    if (self = [super init]) {
        _data = data;
        _currentIndex = 0;
    }
    return self;
}

-(void)appendData:(NSData *)data {
    [_data appendData:data];
}

-(void)appendBytes:(const void *)bytes length:(NSUInteger)length {
    [_data appendBytes:bytes length:length];
}

@end

@interface BMOEDNWriter ()
-(void)appendObject:(id)obj toState:(BMOEDNWriterState *)state;
-(void)appendTaggedObject:(id)obj toState:(BMOEDNWriterState *)state;
-(void)appendVector:(NSArray *)obj toState:(BMOEDNWriterState *)state;
-(void)appendList:(id)obj toState:(BMOEDNWriterState *)state;
-(void)appendMap:(id)obj toState:(BMOEDNWriterState *)state;
-(void)appendString:(NSString *)obj toState:(BMOEDNWriterState *)state;
-(void)appendKeyword:(id)obj toState:(BMOEDNWriterState *)state;
-(void)appendLiteral:(id)obj toState:(BMOEDNWriterState *)state;
-(void)appendNumber:(NSNumber *)obj toState:(BMOEDNWriterState *)state;
-(void)appendSet:(id)obj toState:(BMOEDNWriterState *)state;
@end

@implementation BMOEDNWriter

#pragma mark - external write method

-(NSData *)write:(id)obj error:(NSError **)error {
    NSData * data = [NSMutableData new];
    BMOEDNWriterState *state = [[BMOEDNWriterState alloc] initWithMutableData:data];
    [self appendObject:obj toState:state];
    if (state.error) {
        if (error != NULL) *error = state.error;
        return nil;
    } else return [data copy];
}

#pragma mark - internal write methods

-(void)appendObject:(id)obj toState:(BMOEDNWriterState *)state {
    if ([obj isKindOfClass:[NSString class]])
        [self appendString:obj toState:state];
    else if ([obj isKindOfClass:[NSArray class]])
        [self appendVector:obj toState:state];
    else if ([obj isKindOfClass:[NSNumber class]])
        [self appendNumber:obj toState:state];
    else {
        state.error = BMOEDNErrorMessage(BMOEDNSerializationErrorCodeInvalidData, @"Provided object cannot be EDN-serialized.");
        return;
    }
}

-(void)appendString:(NSString *)obj toState:(BMOEDNWriterState *)state {
    // TODO: profile and optimize... correctness is still job one ATM
    NSMutableString *ednString = [obj mutableCopy];
    
    // quote-town USA
    [ednString replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:NSMakeRange(0, ednString.length)];
    [ednString replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:0 range:NSMakeRange(0, ednString.length)];
    
    // TODO: decide if the following 3 are necessary
    [ednString replaceOccurrencesOfString:@"\r" withString:@"\\r" options:0 range:NSMakeRange(0, ednString.length)];
    [ednString replaceOccurrencesOfString:@"\n" withString:@"\\n" options:0 range:NSMakeRange(0, ednString.length)];
    [ednString replaceOccurrencesOfString:@"\t" withString:@"\\t" options:0 range:NSMakeRange(0, ednString.length)];
    
    // put the endquotes on
    [ednString insertString:@"\"" atIndex:0];
    [ednString appendString:@"\""];
    
    // write it (cut it paste it save it)
    [state appendData:[ednString dataUsingEncoding:NSUTF8StringEncoding]];
}

-(void)appendNumber:(NSNumber *)obj toState:(BMOEDNWriterState *)state {
    // TODO: care more about formatting... also, booleans probably end up here
    [state appendData:[[obj stringValue] dataUsingEncoding:NSUTF8StringEncoding]];
}

-(void)appendVector:(NSArray *)obj toState:(BMOEDNWriterState *)state {
    const void * buffer = "[ ]";
    [state appendBytes:buffer length:2];
    for (id o in obj) {
        [self appendObject:o toState:state];
        [state appendBytes:&buffer[1] length:1];
    }
    [state appendBytes:&buffer[2] length:1];
}

@end
