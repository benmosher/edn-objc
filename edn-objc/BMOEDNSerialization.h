//
//  edn_objc.h
//  edn-objc
//
//  Created by Ben Mosher on 8/24/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum  {
    BMOEDNSerializationErrorCodeNone = 0,
    BMOEDNSerializationErrorCodeNoData,
    BMOEDNSerializationErrorCodeInvalidData,
    BMOEDNSerializationErrorCodeUnexpectedEndOfData,
} BMOEDNSerializationErrorCode;

typedef id (^TaggedEntityResolver)(id, NSError **);

@interface BMOEDNSerialization : NSObject

+(id)EDNObjectWithData:(NSData *)data error:(NSError **)error;
/**
 @param resolvers: a dictionary of EDNSymbols to TaggedEntityResolver blocks
        that turn an EDN object graph into some root object
 */
+(id)EDNObjectWithData:(NSData *)data
             resolvers:(NSDictionary *)resolvers
                 error:(NSError **)error;

@end
