//
//  edn_objc.m
//  edn-objc
//
//  Created by Ben Mosher on 8/24/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "BMOEDNSerialization.h"
#import "BMOEDNList.h"

NSString const * _BMOEDNSerializationErrorDomain = @"BMOEDNSerialization";
#define BMOEDNSerializationErrorDomain ((NSString *)_BMOEDNSerializationErrorDomain)

@interface BMOEDNSerialization ()

+(id)parseObjectWithBytes:(const void *)bytes startingFrom:(NSUInteger)index error:(NSError **)error;

@end
// TODO: profile, see if struct+functions are faster
@interface BMOEDNParserState : NSObject {
    NSUInteger _currentIndex;
    NSUInteger _markIndex;
    __strong NSData * _data;
    char *_chars;
}

-(instancetype)initWithData:(NSData *)data;

@property (nonatomic, readonly, getter = isValid) BOOL valid;
/**
 * Caller should check isValid first; if parser is not
 * in a valid state, behavior is undefined.
 */
@property (nonatomic, readonly) unichar currentCharacter;
@property (nonatomic, readonly) unichar markedCharacter;

@property (strong, nonatomic) NSError * error;

-(void) moveAhead;
-(void) setMark;
-(NSUInteger) getMark;

-(NSString *) markedString;

@end
@implementation BMOEDNParserState

-(instancetype)initWithData:(NSData *)data {
    if (self = [super init]) {
        _data = data;
        _chars = (char *)[data bytes];
        _currentIndex = 0;
    }
    return self;
}

-(BOOL)isValid {
    return (_currentIndex < _data.length);
}

-(unichar)currentCharacter {
    return ((unichar)_chars[_currentIndex]);
};

-(unichar)markedCharacter {
    return ((unichar)_chars[_markIndex]);
}

-(void)moveAhead {
    _currentIndex++;
}

-(void)setMark {
    _markIndex = _currentIndex;
}

-(NSUInteger)getMark {
    return _markIndex;
}

-(NSString *)markedString {
    if (_currentIndex == _markIndex){
        return @"";
    }
    return [[NSString alloc] initWithBytes:&_chars[_markIndex]
                                                 length:(_currentIndex-_markIndex)
                                               encoding:NSUTF8StringEncoding];
}

@end

@interface BMOEDNParser : NSObject {
    // TODO: make these static
    @private
    NSCharacterSet *_whitespace,*_terminators,*_quoted;
}

-(id)parse:(NSData *)data withError:(NSError **)error;

-(id)parseObject:(BMOEDNParserState *)parserState;
-(id)parseTaggedObject:(BMOEDNParserState *)parserState;
-(id)parseVector:(BMOEDNParserState *)parserState;
-(id)parseList:(BMOEDNParserState *)parserState;
-(id)parseMap:(BMOEDNParserState *)parserState;
-(id)parseString:(BMOEDNParserState *)parserState;
-(id)parseLiteral:(BMOEDNParserState *)parserState;
-(id)parseSet:(BMOEDNParserState *)parserState;

-(NSMutableArray *)parseTokenSequenceWithTerminator:(unichar)terminator
                                        parserState:(BMOEDNParserState *)parserState;
-(void)skipWhitespace:(BMOEDNParserState *)parserState;
@property (strong, nonatomic, readonly) NSCharacterSet *whitespace;
@property (strong, nonatomic, readonly) NSCharacterSet *terminators;
@property (strong, nonatomic, readonly) NSCharacterSet *quoted;
@end

@implementation BMOEDNParser

-(id)parse:(NSData *)data withError:(NSError **)error
{
    BMOEDNParserState *state = [[BMOEDNParserState alloc] initWithData:data];
    id parsed = [self parseObject:state];
    if (parsed == nil && error != NULL) {
        *error = state.error;
    }
    return parsed;
}

-(NSCharacterSet *)whitespace {
    if (_whitespace == nil) {
        NSMutableCharacterSet *ws = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
        [ws addCharactersInString:@",;"];
        _whitespace =  [ws copy];
    }
    return _whitespace;
}

-(NSCharacterSet *)terminators {
    if (_terminators == nil) {
        NSMutableCharacterSet *terms = [NSMutableCharacterSet characterSetWithCharactersInString:@"]})"];
        [terms formUnionWithCharacterSet:self.whitespace];
        _terminators = [terms copy];
    }
    return _terminators;
}

-(NSCharacterSet *)quoted {
    if (_quoted == nil) {
        _quoted = [NSCharacterSet characterSetWithCharactersInString:@"\\\"rnt"];
    }
    return _quoted;
}


-(void)skipWhitespace:(BMOEDNParserState *)parserState {
    
    BOOL comment = NO;
    while ((parserState.valid && [self.whitespace characterIsMember:parserState.currentCharacter]) || comment) {
        if (parserState.currentCharacter == ';')
            comment = YES;
        if (parserState.currentCharacter == '\n')
            comment = NO;
        [parserState moveAhead];
    }
}


-(id)parseObject:(BMOEDNParserState *)parserState {
    [self skipWhitespace:parserState];
    if (!parserState.valid) {
        parserState.error = [NSError errorWithDomain:BMOEDNSerializationErrorDomain code:BMOEDNSerializationErrorCodeUnexpectedEndOfData userInfo:nil];
        return nil;
    }
    switch (parserState.currentCharacter) {
        case '#':
            return [self parseTaggedObject:parserState];
        case '[':
            return [self parseVector:parserState];
        case '(':
            return [self parseList:parserState];
        case '{':
            return [self parseMap:parserState];
        case '"':
            return [self parseString:parserState];
        default:
            return [self parseLiteral:parserState];
    }
}

-(id)parseTaggedObject:(BMOEDNParserState *)parserState {
    [parserState moveAhead];
    if (!parserState.valid) {
        parserState.error = [NSError errorWithDomain:BMOEDNSerializationErrorDomain code:BMOEDNSerializationErrorCodeUnexpectedEndOfData userInfo:nil];
        return nil;
    }
    
    switch (parserState.currentCharacter) {
        case '_':
            [parserState moveAhead];
            [self skipWhitespace:parserState];
            while (parserState.valid
                   && ![self.terminators characterIsMember:parserState.currentCharacter]){
                [parserState moveAhead];
            }
            return nil;
        case '{':
            return [self parseSet:parserState];
        default:
            return nil;
            break;
    }
}

-(id)parseSet:(BMOEDNParserState *)parserState {
    NSMutableArray *array = [self parseTokenSequenceWithTerminator:'}' parserState:parserState];
    if (array == nil) return nil;
    // TODO: complain if set count != array length?
    else return [NSSet setWithArray:array];
}

-(id)parseList:(BMOEDNParserState *)parserState {
    [parserState moveAhead];
    if (!parserState.valid) {
        parserState.error = [NSError errorWithDomain:BMOEDNSerializationErrorDomain code:BMOEDNSerializationErrorCodeUnexpectedEndOfData userInfo:nil];
        return nil;
    }
    
    BMOEDNList *list = [BMOEDNList new];
    BMOEDNConsCell *cons = nil;
    
    [self skipWhitespace:parserState];
    while (parserState.valid
           && parserState.currentCharacter != ')') {
        id newObject = [self parseObject:parserState];
        if (parserState.error != nil) {
            return nil;
        }
        if (newObject != nil) {
            BMOEDNConsCell *newCons = [BMOEDNConsCell new];
            newCons.first = newObject;
            if (cons == nil) {
                list.head = newCons;
            } else {
                cons.rest = newCons;
            }
            cons = newCons;
        }
        [self skipWhitespace:parserState];
    }
    [parserState moveAhead];
    return list;
}

-(NSMutableArray *)parseTokenSequenceWithTerminator:(unichar)terminator
                                        parserState:(BMOEDNParserState *)parserState {
    [parserState moveAhead];
    if (!parserState.valid) {
        parserState.error = [NSError errorWithDomain:BMOEDNSerializationErrorDomain code:BMOEDNSerializationErrorCodeUnexpectedEndOfData userInfo:nil];
        return nil;
    }
    NSMutableArray *array = [NSMutableArray new];
    [self skipWhitespace:parserState];
    while (parserState.valid
           && parserState.currentCharacter != terminator) {
        id newObject = [self parseObject:parserState];
        if (parserState.error != nil) {// something went wrong; bail
            return nil;
        }
        if (newObject != nil) {
            [array addObject:newObject];
        }
        [self skipWhitespace:parserState];
    }
    if (!parserState.valid) {
        parserState.error = [NSError errorWithDomain:BMOEDNSerializationErrorDomain code:BMOEDNSerializationErrorCodeUnexpectedEndOfData userInfo:nil];
        return nil;
    }
    [parserState moveAhead];
    return array;
}

-(id)parseVector:(BMOEDNParserState *)parserState {
    NSMutableArray *array = [self parseTokenSequenceWithTerminator:']' parserState:parserState];
    if (array == nil) return nil;
    else return [NSArray arrayWithArray:array];
}

-(id)parseLiteral:(BMOEDNParserState *)parserState {
    
    [parserState setMark];
    while (parserState.valid
           && ![self.terminators characterIsMember:parserState.currentCharacter])
    {
        [parserState moveAhead];
    }
    NSString *literal = [parserState markedString];
    if ([literal length] == 0) {
        parserState.error = [NSError errorWithDomain:BMOEDNSerializationErrorDomain code:BMOEDNSerializationErrorCodeUnexpectedEndOfData userInfo:nil];
        return nil;
    }
    
    // TODO: keyword/symbol support
    if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:parserState.markedCharacter]){
        // TODO: rational number preservation/support?
        // TODO: 'N'-suffix for arbitrary precision (i.e. BigX) support?
        NSNumberFormatter *nf = [NSNumberFormatter new];
        nf.numberStyle = NSNumberFormatterNoStyle;
        return [nf numberFromString:literal];
    } else if ([literal isEqualToString:@"nil"]){
        return [NSNull null];
    } else if ([literal isEqualToString:@"true"]){
        return (__bridge NSNumber *)kCFBooleanTrue;
    } else if ([literal isEqualToString:@"false"]){
        return (__bridge NSNumber *)kCFBooleanFalse;
    }
    
    // failed to parse a valid literal
    // TODO: userinfo
    parserState.error = [NSError errorWithDomain:BMOEDNSerializationErrorDomain
                                 code:BMOEDNSerializationErrorCodeInvalidData
                             userInfo:nil];
    return nil;
}

-(id)parseString:(BMOEDNParserState *)parserState {
    [parserState moveAhead];
    [parserState setMark];
    BOOL quoting = NO;
    while(parserState.valid && (parserState.currentCharacter != '"' || quoting)){
        if (quoting) {
            if (![self.quoted characterIsMember:parserState.currentCharacter]) {
                // TODO: provide erroneous index
                parserState.error = [NSError errorWithDomain:BMOEDNSerializationErrorDomain
                                                        code:BMOEDNSerializationErrorCodeInvalidData
                                                    userInfo:nil];
                return nil;
            } else quoting = NO;
        } else if (parserState.currentCharacter == '\\') {
            quoting = YES;
        }
        [parserState moveAhead];
    }
    NSString *markedString = [parserState markedString];
    if ([markedString length] == 0) return markedString;
    else {
        NSMutableString *string = [markedString mutableCopy];
        // replace escapes with proper values
        [string replaceOccurrencesOfString:@"\\\"" withString:@"\"" options:0 range:NSMakeRange(0, string.length)];
        [string replaceOccurrencesOfString:@"\\t" withString:@"\t" options:0 range:NSMakeRange(0, string.length)];
        [string replaceOccurrencesOfString:@"\\r" withString:@"\r" options:0 range:NSMakeRange(0, string.length)];
        [string replaceOccurrencesOfString:@"\\n" withString:@"\n" options:0 range:NSMakeRange(0, string.length)];
        [string replaceOccurrencesOfString:@"\\\\" withString:@"\\" options:0 range:NSMakeRange(0, string.length)];
        return [NSString stringWithString:string]; // immutabilityyyy
    }

}

@end

@implementation BMOEDNSerialization

+(id)EDNObjectWithData:(NSData *)data error:(NSError **)error {
    return [[BMOEDNParser new] parse:data withError:error];
}

@end
