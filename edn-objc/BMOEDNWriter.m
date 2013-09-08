//
//  BMOEDNWriter.m
//  edn-objc
//
//  Created by Ben Mosher on 8/28/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "BMOEDNWriter.h"
#import "BMOEDNError.h"
#import "BMOEDNKeyword.h"
#import "BMOEDNSymbol.h"
#import "BMOEDNList.h"
#import "BMOEDNRepresentation.h"
#import "NSObject+BMOEDN.h"
// TODO: struct + functions
#import "BMOEDNRoot.h"

#import "BMOEDNWriterState.h"

@interface BMOEDNWriter ()

-(void)appendObject:(id)obj toState:(BMOEDNWriterState *)state;
-(void)appendTaggedObject:(BMOEDNTaggedElement *)obj toState:(BMOEDNWriterState *)state;
-(void)appendVector:(NSArray *)obj toState:(BMOEDNWriterState *)state;
-(void)appendList:(BMOEDNList *)obj toState:(BMOEDNWriterState *)state;
-(void)appendMap:(NSDictionary *)obj toState:(BMOEDNWriterState *)state;
-(void)appendString:(NSString *)obj toState:(BMOEDNWriterState *)state;
-(void)appendSymbol:(BMOEDNSymbol *)obj toState:(BMOEDNWriterState *)state;
-(void)appendNumber:(NSNumber *)obj toState:(BMOEDNWriterState *)state;
-(void)appendSet:(NSSet *)obj toState:(BMOEDNWriterState *)state;

#pragma mark Helpers

-(BMOEDNWriterState *) writeRootObject:(id)obj
                                 state:(BMOEDNWriterState *)state
                                 error:(NSError **)error;

-(void)appendEnumerable:(id<NSFastEnumeration>) obj
                toState:(BMOEDNWriterState *)state
             whitespace:(NSString *)ws;
@end

@implementation BMOEDNWriter

-(instancetype)initWithTransmogrifiers:(NSDictionary *)transmogrifiers {
    if (self = [super init]) {
        _transmogrifiers = transmogrifiers;
    }
    return self;
}

#pragma mark - external write methods

-(BMOEDNWriterState *) writeRootObject:(id)obj state:(BMOEDNWriterState *)state error:(NSError **)error {
    if ([obj isKindOfClass:[BMOEDNRoot class]])
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
                            state:[[BMOEDNWriterState alloc] init]
                            error:error] writtenData];
}

-(NSString *)writeToString:(id)obj
                     error:(NSError **)error {
    return [[self writeRootObject:obj
                            state:[[BMOEDNWriterState alloc] init]
                            error:error] writtenString];
}

-(void)write:(id)obj toStream:(NSOutputStream *)stream
       error:(NSError **)error {
    BMOEDNWriterState *state = [[BMOEDNWriterState alloc] initWithStream:stream];
    [self writeRootObject:obj
                    state:state
                    error:error];
    [state appendString:@"\n"];
}

#pragma mark - internal write methods

-(void)appendObject:(id)obj toState:(BMOEDNWriterState *)state {
    // append meta, if needed.
    NSDictionary *meta;
    if ((meta = [obj ednMetadata]) && [meta count]) {
        [state appendString:@"^"];
        [self appendMap:meta toState:state];
        [state appendString:@" "]; // TODO: whitespace customization
    }
    
    if ([obj conformsToProtocol:@protocol(BMOEDNRepresentation)])
        [self appendTaggedObject:[obj ednRepresentation] toState:state];
    else if ([obj isKindOfClass:[BMOEDNTaggedElement class]])
        [self appendTaggedObject:obj toState:state];
    else if ([obj isKindOfClass:[NSString class]])
        [self appendString:obj toState:state];
    else if ([obj isKindOfClass:[NSDictionary class]])
        [self appendMap:obj toState:state];
    else if ([obj isKindOfClass:[NSArray class]])
        [self appendVector:obj toState:state];
    else if ([obj isKindOfClass:[BMOEDNList class]])
        [self appendList:obj toState:state];
    else if ([obj isKindOfClass:[NSSet class]])
        [self appendSet:obj toState:state];
    else if ([obj isKindOfClass:[NSNumber class]])
        [self appendNumber:obj toState:state];
    else if ([obj isKindOfClass:[BMOEDNSymbol class]])
        [self appendSymbol:obj toState:state];
    else if ([obj isEqual:[NSNull null]])
        [state appendString:@"nil"];
    else {
        // have to iterate over all registered transmogrifiers
        // with isKindOfClass predicate
        __block BMOEDNTransmogrifier transmogrifier = nil;
        [self.transmogrifiers enumerateKeysAndObjectsUsingBlock:^(id key, id val, BOOL *stop) {
            if ([obj isKindOfClass:(Class)key]) {
                transmogrifier = (BMOEDNTransmogrifier)val;
                *stop = YES;
            };
        }];
        if (transmogrifier){
            NSError *err;
            BMOEDNTaggedElement *transmogrifiedObject = transmogrifier(obj,&err);
            if (err) {
                state.error = err;
                return;
            }
            [self appendTaggedObject:transmogrifiedObject toState:state];
        } else {
            state.error = BMOEDNErrorMessage(BMOEDNErrorInvalidData, @"Provided object cannot be EDN-serialized.");
            return;
        }
    }
}

-(void)appendString:(NSString *)obj toState:(BMOEDNWriterState *)state {
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

-(void)appendNumber:(NSNumber *)obj toState:(BMOEDNWriterState *)state {
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
                toState:(BMOEDNWriterState *)state
             whitespace:(NSString *)ws {
    for (id o in obj) {
        [self appendObject:o toState:state];
        if (state.error) return;
        [state appendString:ws];
    }
}

-(void)appendVector:(NSArray *)obj toState:(BMOEDNWriterState *)state {
    // TODO: minimal whitespace (and commas instead of spaces?) version
    [state appendString:@"[ "];
    [self appendEnumerable:obj toState:state whitespace:@" "];
    [state appendString:@"]"];
}

-(void)appendSet:(NSSet *)obj toState:(BMOEDNWriterState *)state {
    [state appendString:@"#{ "];
    [self appendEnumerable:obj toState:state whitespace:@" "];
    [state appendString:@"}"];
}

-(void)appendList:(BMOEDNList *)obj toState:(BMOEDNWriterState *)state {
    [state appendString:@"( "];
    [self appendEnumerable:obj toState:state whitespace:@" "];
    [state appendString:@")"];
}

-(void)appendSymbol:(BMOEDNSymbol *)obj toState:(BMOEDNWriterState *)state {
    [state appendString:[obj description]];
}

-(void)appendTaggedObject:(BMOEDNTaggedElement *)obj
               toState:(BMOEDNWriterState *)state {
    // TODO: test error if taggedElement.element isKindOfClass:BMOEDNTaggedElement?
    [state appendString:@"#"];
    [self appendSymbol:obj.tag toState:state];
    if (state.error) return;
    [state appendString:@" "]; // todo: whitespace option
    [self appendObject:obj.element toState:state];
    if (state.error) return;
}

-(void)appendMap:(NSDictionary *)obj toState:(BMOEDNWriterState *)state {
    [state appendString:@"{ "]; // TODO: whitespace option
    [obj enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self appendObject:key toState:state];
        [state appendString:@" "]; // TODO: whitespace options
        [self appendObject:obj toState:state];
        [state appendString:@" "];
    }];
    [state appendString:@"}"];
}

@end
