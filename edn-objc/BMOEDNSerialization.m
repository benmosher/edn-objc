//
//  edn_objc.m
//  edn-objc
//
//  Created by Ben Mosher on 8/24/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "BMOEDNSerialization.h"
#import "BMOEDNError.h"
#import "BMOEDNList.h"
#import "BMOEDNSymbol.h"
#import "BMOEDNKeyword.h"
#import "BMOEDNReader.h"
#import "BMOEDNWriter.h"
#import "BMOEDNArchiver.h"

@implementation BMOEDNSerialization

+(id)ednObjectWithData:(NSData *)data
               options:(BMOEDNReadingOptions)options
                error:(NSError **)error {
    return [[[BMOEDNReader alloc] initWithOptions:options] parse:data error:error];
}

+(id)ednObjectWithData:(NSData *)data
       transmogrifiers:(NSDictionary *)transmogrifiers
               options:(BMOEDNReadingOptions)options
                 error:(NSError **)error {
    return [[[BMOEDNReader alloc] initWithOptions:options transmogrifiers:transmogrifiers] parse:data error:error];
}

+(id)ednObjectWithStream:(NSInputStream *)data
                 options:(BMOEDNReadingOptions)options
                   error:(NSError **)error; {
    return [[[BMOEDNReader alloc] initWithOptions:options] parseStream:data error:error];
}

+(id)ednObjectWithStream:(NSInputStream *)data
         transmogrifiers:(NSDictionary *)transmogrifiers
                 options:(BMOEDNReadingOptions)options
                   error:(NSError **)error; {
    return [[[BMOEDNReader alloc] initWithOptions:options transmogrifiers:transmogrifiers] parseStream:data error:error];
}

+(NSData *)dataWithEdnObject:(id)obj error:(NSError **)error {
    @try {
        return [BMOEDNArchiver archivedDataWithRootObject:obj];
    } @catch (NSException *e) {
        BMOEDNErrorMessageAssign(error, BMOEDNErrorInvalidData, e.description);
        return nil;
    }
}

+(NSData *)dataWithEdnObject:(id)obj
             transmogrifiers:(NSDictionary *)transmogrifiers
                       error:(NSError **)error {
    BMOEDNWriter *writer = [[BMOEDNWriter alloc] initWithTransmogrifiers:transmogrifiers];
    return [writer writeToData:obj error:error];
}

+(NSString *)stringWithEdnObject:(id)obj error:(NSError **)error {
    @try {
        return [[NSString alloc] initWithData:[BMOEDNArchiver archivedDataWithRootObject:obj] encoding:NSUTF8StringEncoding];
    } @catch (NSException *e) {
        BMOEDNErrorMessageAssign(error, BMOEDNErrorInvalidData, e.description);
        return nil;
    }
}

+(NSString *)stringWithEdnObject:(id)obj
                 transmogrifiers:(NSDictionary *)transmogrifiers
                           error:(NSError **)error {
    BMOEDNWriter *writer = [[BMOEDNWriter alloc] initWithTransmogrifiers:transmogrifiers];
    return [writer writeToString:obj error:error];
}

+(void)writeEdnObject:(id)obj toStream:(NSOutputStream *)stream
                error:(NSError **)error {
    BMOEDNWriter *writer = [[BMOEDNWriter alloc] init];
    [writer write:obj toStream:stream error:error];
}

+(void)writeEdnObject:(id)obj toStream:(NSOutputStream *)stream
      transmogrifiers:(NSDictionary *)transmogrifiers
                error:(NSError **)error {
    BMOEDNWriter *writer = [[BMOEDNWriter alloc] initWithTransmogrifiers:transmogrifiers];
    [writer write:obj toStream:stream error:error];
}
@end
