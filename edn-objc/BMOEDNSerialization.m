//
//  edn_objc.m
//  edn-objc
//
//  Created by Ben Mosher on 8/24/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "BMOEDNSerialization.h"
#import "BMOEDNList.h"
#import "BMOEDNSymbol.h"
#import "BMOEDNKeyword.h"
#import "BMOEDNReader.h"

static NSDictionary * stockReadResolvers;

@implementation BMOEDNSerialization

+(void)initialize {
    if (stockReadResolvers == nil) {
        TaggedEntityResolver uuidBlock = ^(id obj, NSError **error) { 
            id ret = nil;
            if (![obj isKindOfClass:[NSString class]]) {
                *error = BMOEDNErrorMessage(BMOEDNSerializationErrorCodeInvalidData,@"'uuid'-tagged objects should be just a string");
                return (id)nil;
            } else {
                ret = [[NSUUID alloc] initWithUUIDString:obj];
                if (ret == nil) {
                    *error = BMOEDNErrorMessage(BMOEDNSerializationErrorCodeInvalidData,@"'uuid' format did not match expected format.");
                }
            }
            return ret;
        };
        NSString * rfc3339 = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SS'Z'";
        TaggedEntityResolver instBlock = ^(id obj, NSError **error) {
            if (![obj isKindOfClass:[NSString class]]) {
                *error = BMOEDNErrorMessage(BMOEDNSerializationErrorCodeInvalidData,@"'inst'-tagged objects must be an RFC3339-formatted string.");
                return (id)nil;
            } else {
                NSDateFormatter *df = [[NSDateFormatter alloc] init];
                [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
                [df setDateFormat:rfc3339];
                [df setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
                NSDate *date = [df dateFromString:obj];
                if (date == nil) {
                    *error = BMOEDNErrorMessage(BMOEDNSerializationErrorCodeInvalidData,@"'inst'-tagged object must be an RFC3339-formatted string.");
                }
                return (id)date;
            }
        };
        stockReadResolvers =
        @{
          [[BMOEDNSymbol alloc] initWithNamespace:nil name:@"uuid"]:
              [uuidBlock copy],
          [[BMOEDNSymbol alloc] initWithNamespace:nil name:@"inst"]:
              [instBlock copy],
          };
    }
}

+(id)EDNObjectWithData:(NSData *)data error:(NSError **)error {
    return [self EDNObjectWithData:data resolvers:nil error:error];
}

// TODO: throw an error if non-namespaced tags are provided (stock or not?)

+(id)EDNObjectWithData:(NSData *)data
             resolvers:(NSDictionary *)resolvers
                 error:(NSError **)error {
    if (resolvers == nil) {
        resolvers = stockReadResolvers;
    } else if (resolvers != stockReadResolvers) {
        NSMutableDictionary *tempResolvers = [resolvers mutableCopy];
        [tempResolvers addEntriesFromDictionary:stockReadResolvers];
        resolvers = [tempResolvers copy];
    }
    return [[[BMOEDNReader alloc] initWithResolvers:resolvers] parse:data withError:error];
}

@end
