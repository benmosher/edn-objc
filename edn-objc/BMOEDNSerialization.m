//
//  edn_objc.m
//  edn-objc
//
//  Created by Ben Mosher on 8/24/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "BMOEDNSerialization.h"

NSString const * BMOEDNSerializationErrorDomain = @"BMOEDNSerialization";

enum BMOEDNSerializationErrorCode {
    BMOEDNSerializationErrorCodeNone = 0,
    BMOEDNSerializationErrorCodeNoData,
    BMOEDNSerializationErrorCodeUnexpectedEndOfData,
    };

@interface BMOEDNSerialization ()

+(id)parseObjectWithBytes:(const void *)bytes startingFrom:(NSUInteger)index error:(NSError **)error;

@end

@interface BMOEDNParser : NSObject {
    NSUInteger _currentIndex;
    __strong NSData * _data;
    char *_chars;
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
@end

@implementation BMOEDNParser

#if __has_feature(objc_instancetype)
-(instancetype)initWithData:(NSData *)data
#else
-(id)initWithData:(NSData *)data
#endif
{
    if (self = [super init])
    {
        _data = data;
        _chars = [data bytes];
        _currentIndex = 0;
    }
    return self;
}

-(id)parseObjectWithError:(NSError **)error {
    if (_currentIndex >= _data.length)
    {
        *error = [NSError errorWithDomain:BMOEDNSerializationErrorDomain code:BMOEDNSerializationErrorCodeUnexpectedEndOfData userInfo:nil];
        return nil;
    }
    
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

-(id)parseStringWithError:(NSError **)error
{
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
    return [[[BMOEDNParser alloc] initWithData:data] parseObjectWithError:error];
}

@end
