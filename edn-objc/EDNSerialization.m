//
//  edn_objc.m
//  edn-objc
//
//  Created by Ben Mosher on 8/24/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "EDNSerialization.h"
#import "EDNError.h"
#import "EDNList.h"
#import "EDNSymbol.h"
#import "EDNKeyword.h"
#import "EDNReader.h"
#import "EDNWriter.h"
#import "EDNArchiver.h"

@implementation EDNSerialization

+(id)ednObjectWithData:(NSData *)data
               options:(EDNReadingOptions)options
                error:(NSError **)error {
    return [[[EDNReader alloc] initWithOptions:options] parse:data error:error];
}

+(id)ednObjectWithData:(NSData *)data
       transmogrifiers:(NSDictionary *)transmogrifiers
               options:(EDNReadingOptions)options
                 error:(NSError **)error {
    return [[[EDNReader alloc] initWithOptions:options transmogrifiers:transmogrifiers] parse:data error:error];
}

+(id)ednObjectWithStream:(NSInputStream *)data
                 options:(EDNReadingOptions)options
                   error:(NSError **)error; {
    return [[[EDNReader alloc] initWithOptions:options] parseStream:data error:error];
}

+(id)ednObjectWithStream:(NSInputStream *)data
         transmogrifiers:(NSDictionary *)transmogrifiers
                 options:(EDNReadingOptions)options
                   error:(NSError **)error; {
    return [[[EDNReader alloc] initWithOptions:options transmogrifiers:transmogrifiers] parseStream:data error:error];
}

+(NSData *)dataWithEdnObject:(id)obj error:(NSError **)error {
    @try {
        return [EDNArchiver archivedDataWithRootObject:obj];
    } @catch (NSException *e) {
        EDNErrorMessageAssign(error, EDNErrorInvalidData, e.description);
        return nil;
    }
}

+(NSData *)dataWithEdnObject:(id)obj
             transmogrifiers:(NSDictionary *)transmogrifiers
                       error:(NSError **)error {
    EDNWriter *writer = [[EDNWriter alloc] initWithTransmogrifiers:transmogrifiers];
    return [writer writeToData:obj error:error];
}

+(NSString *)stringWithEdnObject:(id)obj error:(NSError **)error {
    @try {
        return [[NSString alloc] initWithData:[EDNArchiver archivedDataWithRootObject:obj] encoding:NSUTF8StringEncoding];
    } @catch (NSException *e) {
        EDNErrorMessageAssign(error, EDNErrorInvalidData, e.description);
        return nil;
    }
}

+(NSString *)stringWithEdnObject:(id)obj
                 transmogrifiers:(NSDictionary *)transmogrifiers
                           error:(NSError **)error {
    EDNWriter *writer = [[EDNWriter alloc] initWithTransmogrifiers:transmogrifiers];
    return [writer writeToString:obj error:error];
}

+(void)writeEdnObject:(id)obj toStream:(NSOutputStream *)stream
                error:(NSError **)error {
    EDNWriter *writer = [[EDNWriter alloc] init];
    [writer write:obj toStream:stream error:error];
}

+(void)writeEdnObject:(id)obj toStream:(NSOutputStream *)stream
      transmogrifiers:(NSDictionary *)transmogrifiers
                error:(NSError **)error {
    EDNWriter *writer = [[EDNWriter alloc] initWithTransmogrifiers:transmogrifiers];
    [writer write:obj toStream:stream error:error];
}
@end
