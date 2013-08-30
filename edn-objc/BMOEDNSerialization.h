//
//  edn_objc.h
//  edn-objc
//
//  Created by Ben Mosher on 8/24/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BMOEDNDefines.pch"

@interface BMOEDNSerialization : NSObject

+(id)EDNObjectWithData:(NSData *)data error:(NSError **)error;
/**
 @param resolvers: a dictionary of EDNSymbols to TaggedEntityResolver blocks
        that turn an EDN object graph into some root object
 */
+(id)EDNObjectWithData:(NSData *)data
             resolvers:(NSDictionary *)resolvers
                 error:(NSError **)error;


+(NSData *)dataWithEDNObject:(id)obj error:(NSError **)error;
+(NSData *)dataWithEDNObject:(id)obj
                   resolvers:(NSDictionary *)resolvers
                       error:(NSError **)error;

+(NSString *)stringWithEDNObject:(id)obj error:(NSError **)error;
+(NSString *)stringWithEDNObject:(id)obj
                   resolvers:(NSDictionary *)resolvers
                       error:(NSError **)error;

/**
 Checks whether 'obj' can be written out to valid EDN (with stock tagged-object resolvers).
 */
+(BOOL)isValidEDNObject:(id)obj;

/**
 Checks whether 'obj' can be written out to valid EDN
 with stock resolvers, and the provided additional resolvers.
 Note that redefinition of existing resolvers will not stick (will be ignored).
 */
+(BOOL)isValidEDNObject:(id)obj withResolvers:(NSDictionary *)resolvers;


@end
