//
//  EDNArchiver.m
//  edn-objc
//
//  Created by Ben Mosher on 7/11/14.
//  Copyright (c) 2014 Ben Mosher. All rights reserved.
//

#import "EDNArchiver.h"
#import "EDNError.h"

#import "EDNKeyword.h"
#import "EDNSymbol.h"
#import "EDNList.h"
#import "EDNRepresentation.h"
#import "NSObject+EDN.h"
#import "EDNCharacter.h"
// TODO: struct + functions
#import "EDNRoot.h"

@interface EDNArchiver ()

// todo: double-check this is the cool way to allocate a strong reference this these days
@property (nonatomic, strong) NSMutableData *data;

-(void)encodeTag:(NSString *)tagName;

-(void)encodeTaggedObject:(EDNTaggedElement *)obj;
-(void)encodeVector:(NSArray *)obj;
-(void)encodeList:(EDNList *)obj;
-(void)encodeMap:(NSDictionary *)obj;
-(void)encodeString:(NSString *)obj;
-(void)encodeSymbol:(EDNSymbol *)obj;
-(void)encodeNumber:(NSNumber *)obj;
-(void)encodeSet:(NSSet *)obj;
-(void)encodeCharacter:(EDNCharacter *)obj;

-(void)encodeEnumerable:(id<NSFastEnumeration>)obj
             whitespace:(const char *)ws
                 length:(NSUInteger)length;

@end

@implementation EDNArchiver

-initForWritingWithMutableData:(NSMutableData *)data {
    if (self = [super init]) {
        _data = data;
    }
    return self;
}

+(NSData *)archivedDataWithRootObject:(id)object {
    NSMutableData *mutableData = [NSMutableData data];
    EDNArchiver *archie = [[EDNArchiver alloc] initForWritingWithMutableData:mutableData];
    [archie encodeRootObject:object];
    return [NSData dataWithData:mutableData];
}


#pragma mark - helpers

-(void)encodeTag:(NSString *)tagName {
    [_data appendBytes:"#edn-objc/" length:10];
    [_data appendData:[tagName dataUsingEncoding:NSUTF8StringEncoding]];
    [_data appendBytes:" " length:1];
}

-(void)encodeKey:(NSString *)key {
    [_data appendBytes:":" length:1];
    // TODO: key format validation or reformat (must be a valid symbol)
    [_data appendData:[key dataUsingEncoding:NSUTF8StringEncoding]];
    [_data appendBytes:" " length:1];
}

-(void)endEncodeKey {
    [_data appendBytes:" " length:1];
}

#pragma mark - guts

-(void)encodeRootObject:(id)rootObject {
    if ([rootObject isKindOfClass:[EDNRoot class]]) {
        [self encodeEnumerable:rootObject whitespace:"\n" length:1]; // TODO: whitespace option
    } else {
        [self encodeObject:rootObject];
    }
}

-(void)encodeString:(NSString *)obj {
    // TODO: profile and optimize... correctness is still job one ATM
    NSMutableString *ednString = [obj mutableCopy];
    
    // quote-town USA
    [ednString replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:NSMakeRange(0, ednString.length)];
    [ednString replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:0 range:NSMakeRange(0, ednString.length)];
    
    // TODO: decide if the following 3 are necessary
    [ednString replaceOccurrencesOfString:@"\r" withString:@"\\r" options:0 range:NSMakeRange(0, ednString.length)];
    [ednString replaceOccurrencesOfString:@"\n" withString:@"\\n" options:0 range:NSMakeRange(0, ednString.length)];
    [ednString replaceOccurrencesOfString:@"\t" withString:@"\\t" options:0 range:NSMakeRange(0, ednString.length)];
    
    // write it (cut it paste it save it)
    [_data appendBytes:"\"" length:1];
    [_data appendData:[ednString dataUsingEncoding:NSUTF8StringEncoding]];
    [_data appendBytes:"\"" length:1];
}

-(void)encodeNumber:(NSNumber *)obj {
    // TODO: care more about formatting
    NSString *stringValue;
    if ((__bridge CFBooleanRef)obj == kCFBooleanTrue) {
        stringValue = @"true";
    } else if ((__bridge CFBooleanRef)obj == kCFBooleanFalse) {
        stringValue = @"false";
    } else {
        stringValue = [obj stringValue];
    }
    [_data appendData:[stringValue dataUsingEncoding:NSUTF8StringEncoding]];
}

-(void)encodeEnumerable:(id<NSFastEnumeration>) obj
             whitespace:(const char *)ws
                 length:(NSUInteger)length {
    for (id o in obj) {
        [self encodeObject:o];
        [_data appendBytes:ws length:length];
    }
}

-(void)encodeVector:(NSArray *)obj {
    // TODO: minimal whitespace (and commas instead of spaces?) version
    [_data appendBytes:"[ " length:2];
    [self encodeEnumerable:obj whitespace:" " length:1];
    [_data appendBytes:"]" length:1];
}

-(void)encodeSet:(NSSet *)obj {
    [_data appendBytes:"#{ " length:3];
    [self encodeEnumerable:obj whitespace:" " length:1];
    [_data appendBytes:"}" length:1];
}

-(void)encodeList:(EDNList *)obj {
    [_data appendBytes:"( " length:2];
    [self encodeEnumerable:obj whitespace:" " length:1];
    [_data appendBytes:")" length:1];
}

-(void)encodeSymbol:(EDNSymbol *)obj {
    [_data appendData:[[obj description] dataUsingEncoding:NSUTF8StringEncoding]];
}

-(void)encodeTaggedObject:(EDNTaggedElement *)obj {
    // TODO: test error if taggedElement.element isKindOfClass:EDNTaggedElement?
    [_data appendBytes:"#" length:1];
    [self encodeSymbol:obj.tag];
    [_data appendBytes:" " length:1]; // todo: whitespace option
    [self encodeObject:obj.element];
}

-(void)encodeMap:(NSDictionary *)obj {
    [_data appendBytes:"{ " length:2]; // TODO: whitespace option
    [obj enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self encodeObject:key];
        [_data appendBytes:" " length:1]; // TODO: whitespace options
        [self encodeObject:obj];
        [_data appendBytes:" " length:1];
    }];
    [_data appendBytes:"}" length:1];
}

-(void)encodeCharacter:(EDNCharacter *)obj {
    switch (obj.unicharValue) {
        case ' ':
            [_data appendBytes:"\\space" length:6];
            break;
        case '\t':
            [_data appendBytes:"\\tab" length:4];
            break;
        case '\r':
            [_data appendBytes:"\\return" length:7];
            break;
        case '\n':
            [_data appendBytes:"\\newline" length:8];
            break;
        default:
        {
            // TODO: certainly not this.
            [_data appendData:[[NSString stringWithFormat:@"\\%C",obj.unicharValue] dataUsingEncoding:NSUTF8StringEncoding]];
             break;
        }
    }
}

#pragma mark - NSCoder

-(void)encodeValueOfObjCType:(const char *)type at:(const void *)addr {
    @throw [NSException exceptionWithName:EDNException reason:@"keyed coding only at this time" userInfo:nil];
}

-(void)encodeDataObject:(NSData *)data {
    [self encodeTag:NSStringFromClass([data classForCoder])];
    [_data appendBytes:"\"" length:1];
    [_data appendData:[data base64EncodedDataWithOptions:0]];
    [_data appendBytes:"\"" length:1];
}

-(void)encodeObject:(id)obj {
    // append meta, if needed.
    NSDictionary *meta;
    if ((meta = [obj ednMetadata]) && [meta count]) {
        [_data appendBytes:"^" length:1];
        [self encodeMap:meta];
        [_data appendBytes:" " length:1]; // TODO: whitespace customization
    }
    if (obj == nil || [obj isEqual:[NSNull null]])
        [_data appendBytes:"nil" length:3];
    else if ([obj isKindOfClass:[NSData class]])
        [self encodeDataObject:obj];
    else if ([obj conformsToProtocol:@protocol(EDNRepresentation)])
        [self encodeTaggedObject:[obj ednRepresentation]];
    else if ([obj isKindOfClass:[EDNTaggedElement class]])
        [self encodeTaggedObject:obj];
    else if ([obj isKindOfClass:[NSString class]])
        [self encodeString:obj];
    else if ([obj isKindOfClass:[NSDictionary class]])
        [self encodeMap:obj];
    else if ([obj isKindOfClass:[NSArray class]])
        [self encodeVector:obj];
    else if ([obj isKindOfClass:[EDNList class]])
        [self encodeList:obj];
    else if ([obj isKindOfClass:[NSSet class]])
        [self encodeSet:obj];
    else if ([obj isKindOfClass:[NSNumber class]])
        [self encodeNumber:obj];
    else if ([obj isKindOfClass:[EDNSymbol class]])
        [self encodeSymbol:obj];
    else if ([obj isKindOfClass:[EDNCharacter class]])
        [self encodeCharacter:obj];
    else if ([obj conformsToProtocol:@protocol(NSCoding)]) {
        [self encodeTag:NSStringFromClass([obj classForCoder])];
        [_data appendBytes:"{ " length:2];
        [obj encodeWithCoder:self];
        [_data replaceBytesInRange:NSMakeRange([_data length]-1, 1) withBytes:" }" length:2];
    } else {
        @throw [NSException exceptionWithName:EDNException reason:@"Provided object cannot be EDN-serialized." userInfo:nil];
    }
}

-(NSInteger)versionForClassName:(NSString *)className {
    @throw [NSException exceptionWithName:EDNException reason:@"keyed coding only at this time" userInfo:nil];
}

#pragma mark - Keyed
     
-(void)encodeBool:(BOOL)boolv forKey:(NSString *)key {
    [self encodeKey:key];
    [_data appendBytes:(boolv ? "true" : "false") length:(boolv ? 4 : 5)];
    [self endEncodeKey];
}

-(void)encodeBytes:(const uint8_t *)bytesp length:(NSUInteger)lenv forKey:(NSString *)key {
    [self encodeKey:key];
    [self encodeDataObject:[NSData dataWithBytesNoCopy:(void *)bytesp length:lenv freeWhenDone:NO]];
    [self endEncodeKey];
}

-(void)encodeDouble:(double)realv forKey:(NSString *)key {
    [self encodeKey:key];
    char *bytes;
    int length = asprintf(&bytes, "%G", realv);
    if (length < 0) {
        @throw [NSException exceptionWithName:EDNException reason:@"unable to allocate string for encoding" userInfo:nil];
    }
    [_data appendBytes:bytes length:(NSUInteger)length];
    free(bytes);
    [self endEncodeKey];
}

-(void)encodeFloat:(float)realv forKey:(NSString *)key {
    [self encodeKey:key];
    char *bytes;
    int length = asprintf(&bytes, "%G", realv);
    if (length < 0) {
        @throw [NSException exceptionWithName:EDNException reason:@"unable to allocate string for encoding" userInfo:nil];
    }
    [_data appendBytes:bytes length:(NSUInteger)length];
    free(bytes);
    [self endEncodeKey];
}

-(void)encodeInt:(int)intv forKey:(NSString *)key {
    [self encodeKey:key];
    char *bytes;
    int length = asprintf(&bytes, "%d", intv);
    if (length < 0) {
        @throw [NSException exceptionWithName:EDNException reason:@"unable to allocate string for encoding" userInfo:nil];
    }
    [_data appendBytes:bytes length:(NSUInteger)length];
    free(bytes);
    [self endEncodeKey];
}

-(void)encodeInt32:(int32_t)intv forKey:(NSString *)key {
    [self encodeKey:key];
    char *bytes;
    int length = asprintf(&bytes, "%d", intv);
    if (length < 0) {
        @throw [NSException exceptionWithName:EDNException reason:@"unable to allocate string for encoding" userInfo:nil];
    }
    [_data appendBytes:bytes length:(NSUInteger)length];
    free(bytes);
    [self endEncodeKey];
}

-(void)encodeInt64:(int64_t)intv forKey:(NSString *)key {
    [self encodeKey:key];
    char *bytes;
    int length = asprintf(&bytes, "%lld", (long long)intv);
    if (length < 0) {
        @throw [NSException exceptionWithName:EDNException reason:@"unable to allocate string for encoding" userInfo:nil];
    }
    [_data appendBytes:bytes length:(NSUInteger)length];
    free(bytes);
    [self endEncodeKey];
}

-(void)encodeInteger:(NSInteger)intv forKey:(NSString *)key {
    [self encodeKey:key];
    char *bytes;
    int length = asprintf(&bytes, "%ld", (long)intv);
    if (length < 0) {
        @throw [NSException exceptionWithName:EDNException reason:@"unable to allocate string for encoding" userInfo:nil];
    }
    [_data appendBytes:bytes length:(NSUInteger)length];
    free(bytes);
    [self endEncodeKey];
}

-(void)encodeObject:(id)objv forKey:(NSString *)key {
    [self encodeKey:key];
    [self encodeObject:objv];
    [self endEncodeKey];
}


@end
