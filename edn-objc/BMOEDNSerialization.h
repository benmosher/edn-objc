//
//  edn_objc.h
//  edn-objc
//
//  Created by Ben Mosher on 8/24/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMOEDNSerialization : NSObject

+(id)EDNObjectWithData:(NSData *)data error:(NSError **)error;
/**
 @param resolvers: a dictionary of EDNSymbols to TaggedEntityResolver blocks
        that turn an EDN object graph into some root object
 */
+(id)EDNObjectWithData:(NSData *)data
       transmogrifiers:(NSDictionary *)transmogrifiers
                 error:(NSError **)error;


+(NSData *)dataWithEDNObject:(id)obj error:(NSError **)error;
+(NSData *)dataWithEDNObject:(id)obj
             transmogrifiers:(NSDictionary *)transmogrifiers
                       error:(NSError **)error;

+(NSString *)stringWithEDNObject:(id)obj error:(NSError **)error;
+(NSString *)stringWithEDNObject:(id)obj
                 transmogrifiers:(NSDictionary *)transmogrifiers
                           error:(NSError **)error;


@end
