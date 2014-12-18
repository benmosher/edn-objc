//
//  EDNWriter.m
//  edn-objc
//
//  Created by Ben Mosher on 8/28/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "EDNWriter.h"
#import "EDNError.h"
#import "EDNKeyword.h"
#import "EDNSymbol.h"
#import "EDNList.h"
#import "EDNRepresentation.h"
#import "NSObject+EDN.h"
#import "EDNCharacter.h"
// TODO: struct + functions
#import "EDNRoot.h"

#import "EDNWriterState.h"

@interface EDNWriter ()

-(void)appendObject:(id)obj toState:(EDNWriterState *)state;
-(void)appendTaggedObject:(EDNTaggedElement *)obj toState:(EDNWriterState *)state;
-(void)appendVector:(NSArray *)obj toState:(EDNWriterState *)state;
-(void)appendList:(EDNList *)obj toState:(EDNWriterState *)state;
-(void)appendMap:(NSDictionary *)obj toState:(EDNWriterState *)state;
-(void)appendString:(NSString *)obj toState:(EDNWriterState *)state;
-(void)appendSymbol:(EDNSymbol *)obj toState:(EDNWriterState *)state;
-(void)appendNumber:(NSNumber *)obj toState:(EDNWriterState *)state;
-(void)appendSet:(NSSet *)obj toState:(EDNWriterState *)state;
-(void)appendCharacter:(EDNCharacter *)obj toState:(EDNWriterState *)state;

#pragma mark Helpers

-(EDNWriterState *) writeRootObject:(id)obj
                                 state:(EDNWriterState *)state
                                 error:(NSError **)error;

-(void)appendEnumerable:(id<NSFastEnumeration>) obj
                toState:(EDNWriterState *)state
             whitespace:(NSString *)ws;
@end

@implementation EDNWriter

-(instancetype)initWithTransmogrifiers:(NSDictionary *)transmogrifiers {
    if (self = [super init]) {
        _transmogrifiers = transmogrifiers;
    }
    return self;
}

#pragma mark - external write methods

-(EDNWriterState *) writeRootObject:(id)obj state:(EDNWriterState *)state error:(NSError **)error {
    if ([obj isKindOfClass:[EDNRoot class]])
        [self appendEnumerable:obj toState:state whitespace:@"\n"]; // TODO: whitespace option
    else
        [self appendObject:obj toState:state];
    if (state.error) {
        if (error != NULL) *error = state.error;
        return nil;
    } else return state;
}

-(NSData *)writeToData:(id)obj
                 error:(NSError **)error {
    return [[self writeRootObject:obj
                            state:[[EDNWriterState alloc] init]
                            error:error] writtenData];
}

-(NSString *)writeToString:(id)obj
                     error:(NSError **)error {
    return [[self writeRootObject:obj
                            state:[[EDNWriterState alloc] init]
                            error:error] writtenString];
}

-(void)write:(id)obj toStream:(NSOutputStream *)stream
       error:(NSError **)error {
    EDNWriterState *state = [[EDNWriterState alloc] initWithStream:stream];
    [self writeRootObject:obj
                    state:state
                    error:error];
    [state appendString:@"\n"];
}

#pragma mark - internal write methods

-(void)appendObject:(id)obj toState:(EDNWriterState *)state {
    // append meta, if needed.
    NSDictionary *meta;
    if ((meta = [obj ednMetadata]) && [meta count]) {
        [state appendString:@"^"];
        [self appendMap:meta toState:state];
        [state appendString:@" "]; // TODO: whitespace customization
    }
    
    if ([obj conformsToProtocol:@protocol(EDNRepresentation)])
        [self appendTaggedObject:[obj ednRepresentation] toState:state];
    else if ([obj isKindOfClass:[EDNTaggedElement class]])
        [self appendTaggedObject:obj toState:state];
    else if ([obj isKindOfClass:[NSString class]])
        [self appendString:obj toState:state];
    else if ([obj isKindOfClass:[NSDictionary class]])
        [self appendMap:obj toState:state];
    else if ([obj isKindOfClass:[NSArray class]])
        [self appendVector:obj toState:state];
    else if ([obj isKindOfClass:[EDNList class]])
        [self appendList:obj toState:state];
    else if ([obj isKindOfClass:[NSSet class]])
        [self appendSet:obj toState:state];
    else if ([obj isKindOfClass:[NSNumber class]])
        [self appendNumber:obj toState:state];
    else if ([obj isKindOfClass:[EDNSymbol class]])
        [self appendSymbol:obj toState:state];
    else if ([obj isEqual:[NSNull null]])
        [state appendString:@"nil"];
    else if ([obj isKindOfClass:[EDNCharacter class]])
        [self appendCharacter:obj toState:state];
    else {
        // have to iterate over all registered transmogrifiers
        // with isKindOfClass predicate
        __block EDNTransmogrifier transmogrifier = nil;
        [self.transmogrifiers enumerateKeysAndObjectsUsingBlock:^(id key, id val, BOOL *stop) {
            if ([obj isKindOfClass:(Class)key]) {
                transmogrifier = (EDNTransmogrifier)val;
                *stop = YES;
            };
        }];
        if (transmogrifier){
            NSError *err;
            EDNTaggedElement *transmogrifiedObject = transmogrifier(obj,&err);
            if (err) {
                state.error = err;
                return;
            }
            [self appendTaggedObject:transmogrifiedObject toState:state];
        } else {
            state.error = EDNErrorMessage(EDNErrorInvalidData, @"Provided object cannot be EDN-serialized.");
            return;
        }
    }
}

-(void)appendString:(NSString *)obj toState:(EDNWriterState *)state {
    // TODO: profile and optimize... correctness is still job one ATM
    
    // wrap in quotes; note that the range on each replacement operation is 1,length-2
    NSMutableString *ednString = [NSMutableString stringWithFormat:@"\"%@\"",obj];
    
    // quote-town USA
    [ednString replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:NSMakeRange(1, ednString.length-2)];
    [ednString replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:0 range:NSMakeRange(1, ednString.length-2)];
    
    // TODO: decide if the following 3 are necessary
    [ednString replaceOccurrencesOfString:@"\r" withString:@"\\r" options:0 range:NSMakeRange(1, ednString.length-2)];
    [ednString replaceOccurrencesOfString:@"\n" withString:@"\\n" options:0 range:NSMakeRange(1, ednString.length-2)];
    [ednString replaceOccurrencesOfString:@"\t" withString:@"\\t" options:0 range:NSMakeRange(1, ednString.length-2)];
    
    // write it (cut it paste it save it)
    [state appendString:ednString];
}

-(void)appendNumber:(NSNumber *)obj toState:(EDNWriterState *)state {
    // TODO: care more about formatting... also, booleans probably end up here
    NSString *stringValue;
    if ((__bridge CFBooleanRef)obj == kCFBooleanTrue) {
        stringValue = @"true";
    } else if ((__bridge CFBooleanRef)obj == kCFBooleanFalse) {
        stringValue = @"false";
    } else {
        stringValue = [obj stringValue];
    }
    [state appendString:stringValue];
}

-(void)appendEnumerable:(id<NSFastEnumeration>) obj
                toState:(EDNWriterState *)state
             whitespace:(NSString *)ws {
    for (id o in obj) {
        [self appendObject:o toState:state];
        if (state.error) return;
        [state appendString:ws];
    }
}

-(void)appendVector:(NSArray *)obj toState:(EDNWriterState *)state {
    // TODO: minimal whitespace (and commas instead of spaces?) version
    [state appendString:@"[ "];
    [self appendEnumerable:obj toState:state whitespace:@" "];
    [state appendString:@"]"];
}

-(void)appendSet:(NSSet *)obj toState:(EDNWriterState *)state {
    [state appendString:@"#{ "];
    [self appendEnumerable:obj toState:state whitespace:@" "];
    [state appendString:@"}"];
}

-(void)appendList:(EDNList *)obj toState:(EDNWriterState *)state {
    [state appendString:@"( "];
    [self appendEnumerable:obj toState:state whitespace:@" "];
    [state appendString:@")"];
}

-(void)appendSymbol:(EDNSymbol *)obj toState:(EDNWriterState *)state {
    [state appendString:[obj description]];
}

-(void)appendTaggedObject:(EDNTaggedElement *)obj
               toState:(EDNWriterState *)state {
    // TODO: test error if taggedElement.element isKindOfClass:EDNTaggedElement?
    [state appendString:@"#"];
    [self appendSymbol:obj.tag toState:state];
    if (state.error) return;
    [state appendString:@" "]; // todo: whitespace option
    [self appendObject:obj.element toState:state];
    if (state.error) return;
}

-(void)appendMap:(NSDictionary *)obj toState:(EDNWriterState *)state {
    [state appendString:@"{ "]; // TODO: whitespace option
    [obj enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self appendObject:key toState:state];
        [state appendString:@" "]; // TODO: whitespace options
        [self appendObject:obj toState:state];
        [state appendString:@" "];
    }];
    [state appendString:@"}"];
}

-(void)appendCharacter:(EDNCharacter *)obj toState:(EDNWriterState *)state {
    switch (obj.unicharValue) {
        case ' ':
            [state appendString:@"\\space"];
            break;
        case '\t':
            [state appendString:@"\\tab"];
            break;
        case '\r':
            [state appendString:@"\\return"];
            break;
        case '\n':
            [state appendString:@"\\newline"];
            break;
        default:
            [state appendString:[NSString stringWithFormat:@"\\%C",obj.unicharValue]];
            break;
    }
}

@end
