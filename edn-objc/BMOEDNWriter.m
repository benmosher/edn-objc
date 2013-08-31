//
//  BMOEDNWriter.m
//  edn-objc
//
//  Created by Ben Mosher on 8/28/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "BMOEDNWriter.h"
#import "BMOEDNDefines.pch"
#import "BMOEDNKeyword.h"
#import "BMOEDNSymbol.h"
#import "BMOEDNList.h"
#import "BMOEDNRepresentation.h"
// TODO: struct + functions

@interface BMOEDNWriterState : NSObject {
    NSUInteger _currentIndex;
    NSMutableString *_mutableString;
}
@property (strong, nonatomic) NSError *error;

-(instancetype)init;

-(void)appendData:(NSData *)data;

-(NSData *)writtenData;
-(NSString *)writtenString;

@end

@implementation BMOEDNWriterState

-(instancetype)init{
    if (self = [super init]) {
        _mutableString = [NSMutableString new];
        _currentIndex = 0;
    }
    return self;
}

-(void)appendString:(NSString *)string {
    [_mutableString appendString:string];
}

-(NSData *)writtenData {
    return [_mutableString dataUsingEncoding:NSUTF8StringEncoding];
}

-(NSString *)writtenString {
    return [_mutableString copy];
}

@end

@interface BMOEDNWriter ()
-(void)appendObject:(id)obj toState:(BMOEDNWriterState *)state;
-(void)appendTaggedObject:(BMOEDNTaggedElement *)obj toState:(BMOEDNWriterState *)state;
-(void)appendVector:(NSArray *)obj toState:(BMOEDNWriterState *)state;
-(void)appendList:(BMOEDNList *)obj toState:(BMOEDNWriterState *)state;
-(void)appendMap:(NSDictionary *)obj toState:(BMOEDNWriterState *)state;
-(void)appendString:(NSString *)obj toState:(BMOEDNWriterState *)state;
-(void)appendSymbol:(BMOEDNSymbol *)obj toState:(BMOEDNWriterState *)state;
-(void)appendLiteral:(id)obj toState:(BMOEDNWriterState *)state;
-(void)appendNumber:(NSNumber *)obj toState:(BMOEDNWriterState *)state;
-(void)appendSet:(NSSet *)obj toState:(BMOEDNWriterState *)state;

#pragma mark Helpers
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

-(NSData *)writeToData:(id)obj error:(NSError **)error {
    BMOEDNWriterState *state = [[BMOEDNWriterState alloc] init];
    [self appendObject:obj toState:state];
    if (state.error) {
        if (error != NULL) *error = state.error;
        return nil;
    } else return [state writtenData];
}

-(NSString *)writeToString:(id)obj error:(NSError **)error {
    BMOEDNWriterState *state = [[BMOEDNWriterState alloc] init];
    [self appendObject:obj toState:state];
    if (state.error) {
        if (error != NULL) *error = state.error;
        return nil;
    } else return [state writtenString];
}

#pragma mark - internal write methods

-(void)appendObject:(id)obj toState:(BMOEDNWriterState *)state {
    
    
    if ([obj conformsToProtocol:@protocol(BMOEDNRepresentation)])
        [self appendTaggedObject:[obj EDNRepresentation] toState:state];
    else if ([obj isKindOfClass:[BMOEDNTaggedElement class]])
        [self appendTaggedObject:obj toState:state];
    else if ([obj isKindOfClass:[NSString class]])
        [self appendString:obj toState:state];
    else if ([obj isKindOfClass:[NSDictionary class]])
        [self appendMap:obj toState:state];
    else if ([obj isKindOfClass:[NSArray class]])
        [self appendVector:obj toState:state];
    else if ([obj isKindOfClass:[NSSet class]])
        [self appendSet:obj toState:state];
    else if ([obj isKindOfClass:[NSNumber class]])
        [self appendNumber:obj toState:state];
    else if ([obj isKindOfClass:[BMOEDNSymbol class]])
        [self appendSymbol:obj toState:state];
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
            state.error = BMOEDNErrorMessage(BMOEDNSerializationErrorCodeInvalidData, @"Provided object cannot be EDN-serialized.");
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
