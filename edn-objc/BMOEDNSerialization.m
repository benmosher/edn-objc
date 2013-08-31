//
//  edn_objc.m
//  edn-objc
//
//  Created by Ben Mosher on 8/24/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "BMOEDNSerialization.h"
#import "BMOEDNDefines.pch"
#import "BMOEDNList.h"
#import "BMOEDNSymbol.h"
#import "BMOEDNKeyword.h"
#import "BMOEDNReader.h"
#import "BMOEDNWriter.h"

@implementation BMOEDNSerialization

+(id)EDNObjectWithData:(NSData *)data error:(NSError **)error {
    return [[[BMOEDNReader alloc] init] parse:data error:error];
}

+(id)EDNObjectWithData:(NSData *)data
             transmogrifiers:(NSDictionary *)transmogrifiers
                 error:(NSError **)error {
    
    return [[[BMOEDNReader alloc] initWithTransmogrifiers:transmogrifiers] parse:data error:error];
}

+(NSData *)dataWithEDNObject:(id)obj error:(NSError **)error {
    BMOEDNWriter *writer = [[BMOEDNWriter alloc] init];
    return [writer writeToData:obj error:error];
}

+(NSString *)stringWithEDNObject:(id)obj error:(NSError **)error {
    BMOEDNWriter *writer = [[BMOEDNWriter alloc] init];
    return [writer writeToString:obj error:error];
}

@end
