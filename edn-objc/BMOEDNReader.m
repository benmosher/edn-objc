//
//  BMOEDNParser.m
//  edn-objc
//
//  Created by Ben Mosher on 8/28/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "BMOEDNReader.h"
#import "BMOEDNReaderState.h"
#import "BMOEDNSymbol.h"
#import "BMOEDNKeyword.h"
#import "BMOEDNList.h"
#import "BMOEDNTaggedElement.h"
#import "BMOEDNRepresentation.h"
#import "BMOEDNRegistry.h"
#import "NSObject+BMOEDN.h"
#import "BMOEDNRoot.h"
#import "BMOLazyEnumerator.h"

static NSCharacterSet *whitespace,*quoted,*numberPrefix,*digits,*symbolChars;

@interface BMOEDNReader () {
    BMOEDNReadingOptions _options;
}

-(id)parseObject:(id<BMOEDNReaderState>)parserState;
-(id)parseTaggedObject:(id<BMOEDNReaderState>)parserState;
-(id)parseVector:(id<BMOEDNReaderState>)parserState;
-(id)parseList:(id<BMOEDNReaderState>)parserState;
-(id)parseMap:(id<BMOEDNReaderState>)parserState;
-(id)parseString:(id<BMOEDNReaderState>)parserState;
-(id)parseKeyword:(id<BMOEDNReaderState>)parserState;
-(id)parseLiteral:(id<BMOEDNReaderState>)parserState;
-(id)parseSet:(id<BMOEDNReaderState>)parserState;

-(NSMutableArray *)parseTokenSequenceWithTerminator:(unichar)terminator
                                        parserState:(id<BMOEDNReaderState>)parserState;
-(void)skipWhitespace:(id<BMOEDNReaderState>)parserState;
@end

#pragma mark - Helper functions

NSError * BMOValidateSymbolComponents(NSString *ns, NSString *name) {
    if ([name rangeOfString:@"/"].location != NSNotFound && name.length > 1) {
        // too many /'s
        // TODO: message(s)
        return BMOEDNErrorMessage(BMOEDNErrorInvalidData,@"Symbol name (of length > 1) must not contain '/'.");
    }
    if (!name.length) {
        // name of 0 length
        return BMOEDNErrorMessage(BMOEDNErrorInvalidData,@"Symbol must not end with '/'.");
    }
    if (ns && !ns.length) {
        // non-nil namespace of 0 length
        return BMOEDNErrorMessage(BMOEDNErrorInvalidData,@"Symbol must not start with '/'.");
    }
    // TODO: number format checking against name; namespace should be clean
    return nil;
}


id BMOParseSymbolType(id<BMOEDNReaderState> parserState, Class symbolClass) {
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

-(instancetype)initWithOptions:(BMOEDNReadingOptions)options {
    return [self initWithOptions:options transmogrifiers:nil];
}

-(instancetype)initWithOptions:(BMOEDNReadingOptions)options
               transmogrifiers:(NSDictionary *)transmogrifiers {
    if (self = [super init]) {
        _options = options;
        _transmogrifiers = transmogrifiers;
    }
    return self;
}

-(id)parseRoot:(id<BMOEDNReaderState>)state {
    if (_options & BMOEDNReadingMultipleObjects) { // gotta parse 'em all
        BMOLazy parser = ^(NSUInteger idx, id last) {
            if (state.error) return (id)nil;
            id parsed = state.valid ? [self parseObject:state] : (id)nil;
            // continue parsing
            if (parsed) [self skipWhitespace:state];
            return state.error ? state.error : parsed;
        };
        
        id enumerator  = [[BMOLazyEnumerator alloc] initWithBlock:parser];
        return (_options & BMOEDNReadingLazyParsing)
            ? [[BMOEDNRoot alloc] initWithEnumerator:enumerator]
            : [[BMOEDNRoot alloc] initWithArray:[enumerator allObjects]];
    } else { // single-object parse; laziness is ignored.
        return [self parseObject:state];
    }
}

-(id)parse:(NSData *)data error:(NSError **)error
{
    id<BMOEDNReaderState> state = [[BMOEDNDataReaderState alloc] initWithData:data];
    id root = [self parseRoot:state];
    if (error != NULL) *error = state.error;
    return (state.error == nil) ? root : nil;

}

-(id)parseStream:(NSInputStream *)data error:(NSError **)error {
    id<BMOEDNReaderState> state = [[BMOEDNStreamReaderState alloc] initWithStream:data];
    id root = [self parseRoot:state];
    if (error != NULL) *error = state.error;
    return (state.error == nil) ? root : nil;
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


-(void)skipWhitespace:(id<BMOEDNReaderState>)parserState {
    
    BOOL comment = NO;
    while ((parserState.valid && [whitespace characterIsMember:parserState.currentCharacter]) || comment) {
        if (parserState.currentCharacter == ';')
            comment = YES;
        if (parserState.currentCharacter == '\n')
            comment = NO;
        [parserState moveAhead];
    }
}


-(id)parseObject:(id<BMOEDNReaderState>)parserState {
    [self skipWhitespace:parserState];
    if (!parserState.valid) {
        parserState.error = [NSError errorWithDomain:BMOEDNErrorDomain code:BMOEDNErrorUnexpectedEndOfData userInfo:nil];
        return nil;
    }
    
    id parsed = nil;
    switch (parserState.currentCharacter) {
        case '^':
        {
            [parserState moveAhead];
            id meta = [self parseMap:parserState];
            if (parserState.error) return nil;
            parsed = [self parseObject:parserState];
            if (parserState.error) return nil;
            if ([parsed EDNMetadata] != nil) {
                parserState.error = BMOEDNErrorMessage(BMOEDNErrorInvalidData, @"Metadata cannot be applied to parsed object with existing metadata.");
                return nil;
            } else {
                [parsed setEDNMetadata:meta];
            }
            break;
        }
        case '#':
            parsed = [self parseTaggedObject:parserState];
            break;
        case '[':
            parsed = [self parseVector:parserState];
            break;
        case '(':
            parsed = [self parseList:parserState];
            break;
        case '{':
            parsed = [self parseMap:parserState];
            break;
        case '"':
            parsed = [self parseString:parserState];
            break;
        case ':':
            parsed = [self parseKeyword:parserState];
            break;
        default:
            parsed = [self parseLiteral:parserState];
            break;
    }
    return parsed;
}

-(id)parseTaggedObject:(id<BMOEDNReaderState>)parserState {
    [parserState moveAhead];
    if (!parserState.valid) {
        parserState.error = [NSError errorWithDomain:BMOEDNErrorDomain code:BMOEDNErrorUnexpectedEndOfData userInfo:nil];
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
            if (parserState.error) return nil;
            
            id innards = [self parseObject:parserState];
            if (parserState.error) return nil;
            BMOEDNTaggedElement *taggedElement = [[BMOEDNTaggedElement alloc] initWithTag:tag element:innards];
            
            // check for fanciness
            Class registeredClass;
            BMOEDNTransmogrifier transmogrifier;
            
            // registered classes take precedence
            if ((registeredClass = BMOEDNRegisteredClassForTag(tag))) {
                NSError *err = nil;
                //id resolvedObject = resolver(innards,&err);
                id registeredObject = [registeredClass objectWithEDNRepresentation:taggedElement error:&err];
                if (err) parserState.error = err;
                return registeredObject;
            } else if ((transmogrifier = self.transmogrifiers[tag])) {
                NSError *err = nil;
                id transmogrifiedObject = transmogrifier(innards,&err);
                if (err) parserState.error = err;
                return transmogrifiedObject;
            } else {
                return taggedElement;
            }
            
            break;
    }
}

-(id)parseSet:(id<BMOEDNReaderState>)parserState {
    NSMutableArray *array = [self parseTokenSequenceWithTerminator:'}' parserState:parserState];
    if (array == nil) return nil;
    NSSet *set = [NSSet setWithArray:array];
    if (set.count != array.count) {
        parserState.error = BMOEDNErrorMessage(BMOEDNErrorInvalidData, @"Sets must contain only unique elements.");
        return nil;
    }
    return set;
}

-(id)parseList:(id<BMOEDNReaderState>)parserState {
    [parserState moveAhead];
    if (!parserState.valid) {
        parserState.error = [NSError errorWithDomain:BMOEDNErrorDomain code:BMOEDNErrorUnexpectedEndOfData userInfo:nil];
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
        // mutation alert!
        if (newObject != nil) {
            BMOEDNConsCell *newCons = [BMOEDNConsCell new];
            newCons->_first = newObject;
            if (cons == nil) {
                list->_head = newCons;
            } else {
                cons->_rest = newCons;
            }
            cons = newCons;
            list->_count++;
        }
        [self skipWhitespace:parserState];
    }
    [parserState moveAhead];
    list->_hashOnceToken = 0; // reset hash token, just in case iOS called it while constructing
    return list;
}

-(id)parseMap:(id<BMOEDNReaderState>)parserState {
    NSMutableArray *array = [self parseTokenSequenceWithTerminator:'}' parserState:parserState];
    if (parserState.error != nil) {
        return array; // bad things afoot
    }
    if (array.count%2 == 1) {
        parserState.error = [NSError errorWithDomain:BMOEDNErrorDomain code:BMOEDNErrorInvalidData userInfo:nil]; // TODO: message
        return nil;
    }
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:(array.count/2)];
    
    for (int i = 0; i < array.count; i += 2)
    {
        [dictionary setObject:[array objectAtIndex:i+1] forKey:[array objectAtIndex:i]];
    }
    if (dictionary.count != array.count/2) {
        parserState.error = [NSError errorWithDomain:BMOEDNErrorDomain code:BMOEDNErrorInvalidData userInfo:nil]; // TODO: message
        return nil;
    }
    return [dictionary copy];
}

-(NSMutableArray *)parseTokenSequenceWithTerminator:(unichar)terminator
                                        parserState:(id<BMOEDNReaderState>)parserState {
    [parserState moveAhead];
    if (!parserState.valid) {
        parserState.error = [NSError errorWithDomain:BMOEDNErrorDomain code:BMOEDNErrorUnexpectedEndOfData userInfo:nil];
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
    // if terminator is '\0', we're parsing all tokens,
    // so the parsing stops when the state is invalid
    if (!parserState.valid && terminator != '\0') {
        parserState.error = [NSError errorWithDomain:BMOEDNErrorDomain code:BMOEDNErrorUnexpectedEndOfData userInfo:nil];
        return nil;
    }
    [parserState moveAhead];
    return array;
}

-(id)parseVector:(id<BMOEDNReaderState>)parserState {
    NSMutableArray *array = [self parseTokenSequenceWithTerminator:']' parserState:parserState];
    if (array == nil) return nil;
    else return [NSArray arrayWithArray:array];
}

// TODO: interning, probably via a map of namespaces
-(id)parseKeyword:(id<BMOEDNReaderState>)parserState {
    [parserState moveAhead];
    [parserState setMark];
    while (parserState.valid
           && [symbolChars characterIsMember:parserState.currentCharacter])
    {
        [parserState moveAhead];
    }
    
    if ([parserState markedLength] == 0) {
        parserState.error = BMOEDNErrorMessage(BMOEDNErrorInvalidData, @"Keyword must not be empty.");
        return nil;
    }
    
    return BMOParseSymbolType(parserState, [BMOEDNKeyword class]);
}

-(id)parseLiteral:(id<BMOEDNReaderState>)parserState {
    [parserState setMark];
    while (parserState.valid
           && [symbolChars characterIsMember:parserState.currentCharacter])
    {
        [parserState moveAhead];
    }
    
    if ([parserState markedLength] == 0) {
        parserState.error = [NSError errorWithDomain:BMOEDNErrorDomain code:BMOEDNErrorUnexpectedEndOfData userInfo:nil];
        return nil;
    }
    
    NSMutableString *literal = [parserState markedString];
    if ([digits characterIsMember:[literal characterAtIndex:0]] ||
        (literal.length > 1
         && [numberPrefix characterIsMember:[literal characterAtIndex:0]]
         && [digits characterIsMember:[literal characterAtIndex:1]])){
            
            // TODO: give up if N is non-integer or M is non-float? or leniency option?
            if ([literal hasSuffix:@"M"] || [literal hasSuffix:@"N"]) {
                [literal deleteCharactersInRange:NSMakeRange(literal.length-1, 1)];
            }
            return [NSDecimalNumber decimalNumberWithString:literal locale:[NSLocale systemLocale]];
            
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
    parserState.error = [NSError errorWithDomain:BMOEDNErrorDomain
                                            code:BMOEDNErrorInvalidData
                                        userInfo:nil];
    return nil;
}

-(id)parseString:(id<BMOEDNReaderState>)parserState {
    [parserState moveAhead];
    [parserState setMark];
    BOOL quoting = NO;
    while(parserState.valid && (parserState.currentCharacter != '"' || quoting)){
        if (quoting) {
            if (![quoted characterIsMember:parserState.currentCharacter]) {
                // TODO: provide erroneous index
                parserState.error = [NSError errorWithDomain:BMOEDNErrorDomain
                                                        code:BMOEDNErrorInvalidData
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
