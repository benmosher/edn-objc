//
//  BMOEDNParser.m
//  edn-objc
//
//  Created by Ben Mosher on 8/28/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "BMOEDNReader.h"
#import "BMOEDNSymbol.h"
#import "BMOEDNKeyword.h"
#import "BMOEDNList.h"

// TODO: profile, see if struct+functions are faster
@interface BMOEDNReaderState : NSObject {
    NSUInteger _currentIndex;
    NSUInteger _markIndex;
    __strong NSData * _data;
    char *_chars;
}

-(instancetype)initWithData:(NSData *)data;

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
-(void) moveMarkByOffset:(NSInteger)offset;
/**
 Set mark to current parser index.
 */
-(void) setMark;
-(NSUInteger) markedLength;
-(NSMutableString *) markedString;

@end
@implementation BMOEDNReaderState

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

-(void)moveMarkByOffset:(NSInteger)offset {
    if (!BMOOffsetInRange(_markIndex, _data.length, offset))
        @throw [NSException exceptionWithName:NSRangeException reason:@"Cannot move mark out of range of data." userInfo:nil];
    _markIndex += offset;
}

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

static NSCharacterSet *whitespace,*quoted,*numberPrefix,*digits,*symbolChars;

@interface BMOEDNReader ()
-(id)parseObject:(BMOEDNReaderState *)parserState;
-(id)parseTaggedObject:(BMOEDNReaderState *)parserState;
-(id)parseVector:(BMOEDNReaderState *)parserState;
-(id)parseList:(BMOEDNReaderState *)parserState;
-(id)parseMap:(BMOEDNReaderState *)parserState;
-(id)parseString:(BMOEDNReaderState *)parserState;
-(id)parseKeyword:(BMOEDNReaderState *)parserState;
-(id)parseLiteral:(BMOEDNReaderState *)parserState;
-(id)parseSet:(BMOEDNReaderState *)parserState;

-(NSMutableArray *)parseTokenSequenceWithTerminator:(unichar)terminator
                                        parserState:(BMOEDNReaderState *)parserState;
-(void)skipWhitespace:(BMOEDNReaderState *)parserState;
@end

#pragma mark - Helper functions

NSError * BMOValidateSymbolComponents(NSString *ns, NSString *name) {
    if ([name rangeOfString:@"/"].location != NSNotFound && name.length > 1) {
        // too many /'s
        // TODO: message(s)
        return BMOEDNErrorMessage(BMOEDNSerializationErrorCodeInvalidData,@"Symbol name (of length > 1) must not contain '/'.");
    }
    if (!name.length) {
        // name of 0 length
        return BMOEDNErrorMessage(BMOEDNSerializationErrorCodeInvalidData,@"Symbol must not end with '/'.");
    }
    if (ns && !ns.length) {
        // non-nil namespace of 0 length
        return BMOEDNErrorMessage(BMOEDNSerializationErrorCodeInvalidData,@"Symbol must not start with '/'.");
    }
    // TODO: number format checking against name; namespace should be clean
    return nil;
}


id BMOParseSymbolType(BMOEDNReaderState *parserState, Class symbolClass) {
    NSString *ns = nil, *name;
    NSMutableString *symbol = parserState.markedString;
    NSRange namespaceFulcrum = [symbol rangeOfString:@"/"];
    if (namespaceFulcrum.location == NSNotFound || symbol.length == 1) {
        name = [symbol copy];
    } else {
        ns = [symbol substringToIndex:namespaceFulcrum.location];
        name = [symbol substringFromIndex:(namespaceFulcrum.location+namespaceFulcrum.length)];
    }
    
    NSError *err = BMOValidateSymbolComponents(ns,name);
    if (err) {
        parserState.error = err;
        return nil;
    }
    return [[symbolClass alloc] initWithNamespace:ns name:name];
}

@implementation BMOEDNReader

-(instancetype)initWithResolvers:(NSDictionary *)resolvers {
    if (self = [super init]) {
        _resolvers = resolvers;
    }
    return self;
}

-(id)parse:(NSData *)data withError:(NSError **)error
{
    BMOEDNReaderState *state = [[BMOEDNReaderState alloc] initWithData:data];
    id parsed = [self parseObject:state];
    if (parsed == nil && error != NULL) {
        *error = state.error;
    }
    return parsed;
}

+(void)initialize {
    if (whitespace == nil) {
        NSMutableCharacterSet *ws = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
        [ws addCharactersInString:@",;"];
        whitespace =  [ws copy];
    }
    if (quoted == nil) {
        quoted = [NSCharacterSet characterSetWithCharactersInString:@"\\\"rnt"];
    }
    if (numberPrefix == nil) {
        numberPrefix = [NSCharacterSet characterSetWithCharactersInString:@"+-."];
    }
    if (digits == nil) {
        digits = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    }
    if (symbolChars == nil) {
        symbolChars = [NSCharacterSet characterSetWithCharactersInString:
                       @"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.*+!-_?$%&=:#/"];
    }
}


-(void)skipWhitespace:(BMOEDNReaderState *)parserState {
    
    BOOL comment = NO;
    while ((parserState.valid && [whitespace characterIsMember:parserState.currentCharacter]) || comment) {
        if (parserState.currentCharacter == ';')
            comment = YES;
        if (parserState.currentCharacter == '\n')
            comment = NO;
        [parserState moveAhead];
    }
}


-(id)parseObject:(BMOEDNReaderState *)parserState {
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
        case ':':
            return [self parseKeyword:parserState];
        default:
            return [self parseLiteral:parserState];
    }
}

-(id)parseTaggedObject:(BMOEDNReaderState *)parserState {
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
                   && [symbolChars characterIsMember:parserState.currentCharacter]){
                [parserState moveAhead];
            }
            return nil;
        case '{':
            return [self parseSet:parserState];
        default:
            [parserState setMark];
            while (parserState.valid
                   && [symbolChars characterIsMember:parserState.currentCharacter]) {
                [parserState moveAhead];
            }
            id tag = BMOParseSymbolType(parserState,[BMOEDNSymbol class]);
            TaggedEntityResolver resolver = self.resolvers[tag];
            if (resolver == nil) {
                // TODO: reversible tagged object implementation
                parserState.error = BMOEDNErrorMessage(BMOEDNSerializationErrorCodeInvalidData, @"Tag for tagged data type not recognized; arbitrary tags not currently supported.");
                return nil;
            } else {
                id innards = [self parseObject:parserState];
                if (parserState.error) return nil;
                NSError *err = nil;
                id resolvedObject = resolver(innards,&err);
                if (err) parserState.error = err;
                return resolvedObject;
            }
            
            break;
    }
}

-(id)parseSet:(BMOEDNReaderState *)parserState {
    NSMutableArray *array = [self parseTokenSequenceWithTerminator:'}' parserState:parserState];
    if (array == nil) return nil;
    NSSet *set = [NSSet setWithArray:array];
    if (set.count != array.count) {
        parserState.error = BMOEDNErrorMessage(BMOEDNSerializationErrorCodeInvalidData, @"Sets must contain only unique elements.");
        return nil;
    }
    return set;
}

-(id)parseList:(BMOEDNReaderState *)parserState {
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
            newCons->_first = newObject;
            if (cons == nil) {
                list->_head = newCons;
            } else {
                cons->_rest = newCons;
            }
            cons = newCons;
        }
        [self skipWhitespace:parserState];
    }
    [parserState moveAhead];
    list->_hashOnceToken = 0; // reset hash token, just in case iOS called it while constructing
    return list;
}

-(id)parseMap:(BMOEDNReaderState *)parserState {
    NSMutableArray *array = [self parseTokenSequenceWithTerminator:'}' parserState:parserState];
    if (parserState.error != nil) {
        return array; // bad things afoot
    }
    if (array.count%2 == 1) {
        parserState.error = [NSError errorWithDomain:BMOEDNSerializationErrorDomain code:BMOEDNSerializationErrorCodeInvalidData userInfo:nil]; // TODO: message
        return nil;
    }
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:(array.count/2)];
    
    for (int i = 0; i < array.count; i += 2)
    {
        [dictionary setObject:[array objectAtIndex:i+1] forKey:[array objectAtIndex:i]];
    }
    if (dictionary.count != array.count/2) {
        parserState.error = [NSError errorWithDomain:BMOEDNSerializationErrorDomain code:BMOEDNSerializationErrorCodeInvalidData userInfo:nil]; // TODO: message
        return nil;
    }
    return [dictionary copy];
}

-(NSMutableArray *)parseTokenSequenceWithTerminator:(unichar)terminator
                                        parserState:(BMOEDNReaderState *)parserState {
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

-(id)parseVector:(BMOEDNReaderState *)parserState {
    NSMutableArray *array = [self parseTokenSequenceWithTerminator:']' parserState:parserState];
    if (array == nil) return nil;
    else return [NSArray arrayWithArray:array];
}

// TODO: interning, probably via a map of namespaces
-(id)parseKeyword:(BMOEDNReaderState *)parserState {
    [parserState moveAhead];
    [parserState setMark];
    while (parserState.valid
           && [symbolChars characterIsMember:parserState.currentCharacter])
    {
        [parserState moveAhead];
    }
    
    if ([parserState markedLength] == 0) {
        parserState.error = BMOEDNErrorMessage(BMOEDNSerializationErrorCodeInvalidData, @"Keyword must not be empty.");
        return nil;
    }
    
    return BMOParseSymbolType(parserState, [BMOEDNKeyword class]);
}

-(id)parseLiteral:(BMOEDNReaderState *)parserState {
    [parserState setMark];
    while (parserState.valid
           && [symbolChars characterIsMember:parserState.currentCharacter])
    {
        [parserState moveAhead];
    }
    
    if ([parserState markedLength] == 0) {
        parserState.error = [NSError errorWithDomain:BMOEDNSerializationErrorDomain code:BMOEDNSerializationErrorCodeUnexpectedEndOfData userInfo:nil];
        return nil;
    }
    
    NSMutableString *literal = [parserState markedString];
    if ([digits characterIsMember:parserState.markedCharacter] ||
        ([numberPrefix characterIsMember:parserState.markedCharacter]
         && [digits characterIsMember:[parserState characterOffsetFromMark:1]])){
            
            if ([literal hasSuffix:@"M"]) {
                [literal deleteCharactersInRange:NSMakeRange(literal.length-1, 1)];
                // must use '.' as the decimal separator for format compliance
                return [NSDecimalNumber decimalNumberWithString:literal locale:[NSLocale systemLocale]];
            } else {
                // remove leading '+' (NSNumberFormatter won't like it)
                if ([literal hasPrefix:@"+"]) {
                    [literal deleteCharactersInRange:NSMakeRange(0, 1)];
                }
                if ([literal hasSuffix:@"N"]) {
                    // TODO: 'N'-suffix for arbitrary precision (i.e. BigX) support?
                    [literal deleteCharactersInRange:NSMakeRange(literal.length-1, 1)];
                }
                NSNumberFormatter *nf = [NSNumberFormatter new];
                nf.numberStyle = NSNumberFormatterNoStyle;
                return [nf numberFromString:literal];
            }
        } else if ([literal isEqualToString:@"nil"]){
            return [NSNull null];
        } else if ([literal isEqualToString:@"true"]){
            return (__bridge NSNumber *)kCFBooleanTrue;
        } else if ([literal isEqualToString:@"false"]){
            return (__bridge NSNumber *)kCFBooleanFalse;
        } else {
            return BMOParseSymbolType(parserState, [BMOEDNSymbol class]);
        }
    // failed to parse a valid literal
    // TODO: userinfo
    parserState.error = [NSError errorWithDomain:BMOEDNSerializationErrorDomain
                                            code:BMOEDNSerializationErrorCodeInvalidData
                                        userInfo:nil];
    return nil;
}

-(id)parseString:(BMOEDNReaderState *)parserState {
    [parserState moveAhead];
    [parserState setMark];
    BOOL quoting = NO;
    while(parserState.valid && (parserState.currentCharacter != '"' || quoting)){
        if (quoting) {
            if (![quoted characterIsMember:parserState.currentCharacter]) {
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
    
    NSString *string = @"";
    
    if ([parserState markedLength] > 0) {
        NSMutableString *markedString = [parserState markedString];
        // Replace escapes with proper values
        // Have to regen the range each time, as the string may
        // get shorter if replacements occur.
        [markedString replaceOccurrencesOfString:@"\\\"" withString:@"\"" options:0 range:NSMakeRange(0, markedString.length)];
        [markedString replaceOccurrencesOfString:@"\\t" withString:@"\t" options:0 range:NSMakeRange(0, markedString.length)];
        [markedString replaceOccurrencesOfString:@"\\r" withString:@"\r" options:0 range:NSMakeRange(0, markedString.length)];
        [markedString replaceOccurrencesOfString:@"\\n" withString:@"\n" options:0 range:NSMakeRange(0, markedString.length)];
        [markedString replaceOccurrencesOfString:@"\\\\" withString:@"\\" options:0 range:NSMakeRange(0, markedString.length)];
        string = [markedString copy]; // immutabilityyyy
    }
    [parserState moveAhead];
    return string;
}

@end
