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

@implementation BMOEDNSerialization

+(id)EDNObjectWithData:(NSData *)data
               options:(BMOEDNReadingOptions)options
                error:(NSError **)error {
    return [[[BMOEDNReader alloc] initWithOptions:options] parse:data error:error];
}

+(id)EDNObjectWithData:(NSData *)data
       transmogrifiers:(NSDictionary *)transmogrifiers
               options:(BMOEDNReadingOptions)options
                 error:(NSError **)error {
    return [[[BMOEDNReader alloc] initWithOptions:options transmogrifiers:transmogrifiers] parse:data error:error];
}

+(id)EDNObjectWithStream:(NSInputStream *)data
                 options:(BMOEDNReadingOptions)options
                   error:(NSError **)error; {
    return [[[BMOEDNReader alloc] initWithOptions:options] parseStream:data error:error];
}

+(id)EDNObjectWithStream:(NSInputStream *)data
         transmogrifiers:(NSDictionary *)transmogrifiers
                 options:(BMOEDNReadingOptions)options
                   error:(NSError **)error; {
    return [[[BMOEDNReader alloc] initWithOptions:options transmogrifiers:transmogrifiers] parseStream:data error:error];
}

+(NSData *)dataWithEDNObject:(id)obj error:(NSError **)error {
    BMOEDNWriter *writer = [[BMOEDNWriter alloc] init];
    return [writer writeToData:obj error:error];
}

+(NSData *)dataWithEDNObject:(id)obj
             transmogrifiers:(NSDictionary *)transmogrifiers
                       error:(NSError **)error {
    BMOEDNWriter *writer = [[BMOEDNWriter alloc] initWithTransmogrifiers:transmogrifiers];
    return [writer writeToData:obj error:error];
}

+(NSString *)stringWithEDNObject:(id)obj error:(NSError **)error {
    BMOEDNWriter *writer = [[BMOEDNWriter alloc] init];
    return [writer writeToString:obj error:error];
}

+(NSString *)stringWithEDNObject:(id)obj
                 transmogrifiers:(NSDictionary *)transmogrifiers
                           error:(NSError **)error {
    BMOEDNWriter *writer = [[BMOEDNWriter alloc] initWithTransmogrifiers:transmogrifiers];
    return [writer writeToString:obj error:error];
}

+(void)writeEDNObject:(id)obj toStream:(NSOutputStream *)stream
                error:(NSError **)error {
    BMOEDNWriter *writer = [[BMOEDNWriter alloc] init];
    [writer write:obj toStream:stream error:error];
}

+(void)writeEDNObject:(id)obj toStream:(NSOutputStream *)stream
      transmogrifiers:(NSDictionary *)transmogrifiers
                error:(NSError **)error {
    BMOEDNWriter *writer = [[BMOEDNWriter alloc] initWithTransmogrifiers:transmogrifiers];
    [writer write:obj toStream:stream error:error];
}
@end
