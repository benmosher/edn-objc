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

/**
 * Indicator type for collections, etc., since 'nil'
 * already means "propogate the error". Should be 
 * removed if recursion is converted to iteration.
 */
@interface BMOEDNDiscard : NSObject
@end
@implementation BMOEDNDiscard
@end

@interface BMOEDNParser : NSObject {
    NSUInteger _currentIndex;
    __strong NSData * _data;
    char *_chars;
    
    @private
    NSCharacterSet *_whitespace,*_terminators;
}
#if __has_feature(objc_instancetype)
-(instancetype)initWithData:(NSData *)data;
#else
-(id)initWithData:(NSData *)data;
#endif

-(id)parseObjectWithError:(NSError **)error;
-(id)parseTaggedObjectWithError:(NSError **)error;
-(id)parseVectorWithError:(NSError **)error;
-(id)parseListWithError:(NSError **)error;
-(id)parseMapWithError:(NSError **)error;
-(id)parseStringWithError:(NSError **)error;
-(id)parseLiteralWithError:(NSError **)error;

-(void)skipWhitespace;
@property (strong, nonatomic, readonly) NSCharacterSet *whitespace;
@property (strong, nonatomic, readonly) NSCharacterSet *terminators;
@end

@implementation BMOEDNParser

#if __has_feature(objc_instancetype)
-(instancetype)initWithData:(NSData *)data
#else
-(id)initWithData:(NSData *)data
#endif
{
    if (self = [super init]) {
        _data = data;
        _chars = (char *)[data bytes];
        _currentIndex = 0;
    }
    return self;
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


-(void)skipWhitespace {
    
    BOOL comment = NO;
    while ((_currentIndex < _data.length
           && [self.whitespace characterIsMember:(unichar)_chars[_currentIndex]]) || comment) {
        if (_chars[_currentIndex] == ';')
            comment = YES;
        if ( _chars[_currentIndex] == '\n')
            comment = NO;
        _currentIndex++;
    }
}


-(id)parseObjectWithError:(NSError **)error {
    [self skipWhitespace];
    if (_currentIndex >= _data.length) {
        *error = [NSError errorWithDomain:BMOEDNSerializationErrorDomain code:BMOEDNSerializationErrorCodeUnexpectedEndOfData userInfo:nil];
        return nil;
    }
    // TODO: ignore leading whitespace
    switch (_chars[_currentIndex]) {
        case '#':
            return [self parseTaggedObjectWithError:error];
        case '[':
            return [self parseVectorWithError:error];
        case '(':
            return [self parseListWithError:error];
        case '{':
            return [self parseMapWithError:error];
        case '"':
            return [self parseStringWithError:error];
        default:
            return [self parseLiteralWithError:error];
    }
}

-(id)parseTaggedObjectWithError:(NSError **)error {
    _currentIndex++;
    if (_currentIndex >= _data.length) {
        *error = [NSError errorWithDomain:BMOEDNSerializationErrorDomain code:BMOEDNSerializationErrorCodeUnexpectedEndOfData userInfo:nil];
        return nil;
    }
    
    switch (_chars[_currentIndex]) {
        case '_':
            _currentIndex++;
            [self skipWhitespace];
            while (_currentIndex < _data.length
                   && ![self.terminators characterIsMember:(unichar)_chars[_currentIndex]]){
                _currentIndex++;
            }
            return [BMOEDNDiscard new]; // TODO: singleton? or just figure out how to obviate?
            
        default:
            return nil;
            break;
    }
}

-(id)parseListWithError:(NSError **)error {
    _currentIndex++;
    if (_currentIndex >= _data.length) {
        *error = [NSError errorWithDomain:BMOEDNSerializationErrorDomain code:BMOEDNSerializationErrorCodeUnexpectedEndOfData userInfo:nil];
        return nil;
    }
    
    BMOEDNList *list = [BMOEDNList new];
    BMOEDNConsCell *cons = nil;
    
    [self skipWhitespace];
    while (_currentIndex < _data.length
           && _chars[_currentIndex] != ')') {
        id newObject = [self parseObjectWithError:error];
        if (newObject == nil) {
            return nil;
        }
        if (![newObject isKindOfClass:[BMOEDNDiscard class]]) {
            BMOEDNConsCell *newCons = [BMOEDNConsCell new];
            newCons.first = newObject;
            if (cons == nil) {
                list.head = newCons;
            } else {
                cons.rest = newCons;
            }
            cons = newCons;
        }
        [self skipWhitespace];
    }
    return list;
}

-(id)parseVectorWithError:(NSError **)error {
    _currentIndex++;
    if (_currentIndex >= _data.length) {
        *error = [NSError errorWithDomain:BMOEDNSerializationErrorDomain code:BMOEDNSerializationErrorCodeUnexpectedEndOfData userInfo:nil];
        return nil;
    }
    NSMutableArray *array = [NSMutableArray new];
    [self skipWhitespace];
    while (_currentIndex < _data.length
           && _chars[_currentIndex] != ']') {
        id newObject = [self parseObjectWithError:error];
        if (newObject == nil) {// something went wrong; bail
            return nil;
        }
        if (![newObject isKindOfClass:[BMOEDNDiscard class]]) {
            [array addObject:newObject];
        }
        [self skipWhitespace];
    }
    if (_currentIndex >= _data.length) {
        *error = [NSError errorWithDomain:BMOEDNSerializationErrorDomain code:BMOEDNSerializationErrorCodeUnexpectedEndOfData userInfo:nil];
        return nil;
    }
    _currentIndex++;
    return [NSArray arrayWithArray:array];
}

-(id)parseLiteralWithError:(NSError **)error {
    NSUInteger firstCharIndex = _currentIndex;
    
    while (_currentIndex < _data.length
           && ![self.terminators characterIsMember:(unichar)_chars[_currentIndex]])
    {
        _currentIndex++;
    }
    
    if (_currentIndex == firstCharIndex){
        // TODO: userinfo
        *error = [NSError errorWithDomain:BMOEDNSerializationErrorDomain
                                     code:BMOEDNSerializationErrorCodeUnexpectedEndOfData
                                 userInfo:nil];
        return nil;
    }
    NSString *literal = [[NSString alloc] initWithBytes:&_chars[firstCharIndex]
                                                 length:(_currentIndex-firstCharIndex)
                                               encoding:NSUTF8StringEncoding];
    // TODO: keyword/symbol support
    if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:(unichar)_chars[firstCharIndex]]){
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
    *error = [NSError errorWithDomain:BMOEDNSerializationErrorDomain
                                 code:BMOEDNSerializationErrorCodeInvalidData
                             userInfo:nil];
    return nil;
}

-(id)parseStringWithError:(NSError **)error {
    NSUInteger firstChar = ++_currentIndex;
    while(_currentIndex < _data.length && (_chars[_currentIndex] != '"' || _chars[_currentIndex-1] == '\\')){
        _currentIndex++;
    }
    if (_currentIndex == firstChar){
        return @"";
    }
    else {
        NSMutableString *string = [[NSMutableString alloc] initWithBytes:&_chars[firstChar]
                                                           length:(_currentIndex-firstChar)
                                                         encoding:NSUTF8StringEncoding];
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
    id parsed = [[[BMOEDNParser alloc] initWithData:data] parseObjectWithError:error];
    if ([parsed isKindOfClass:[BMOEDNDiscard class]]) {
        *error = [NSError errorWithDomain:BMOEDNSerializationErrorDomain code:BMOEDNSerializationErrorCodeNoData userInfo:nil];
        parsed = nil;
    }
    return parsed;
}

@end
