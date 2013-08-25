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

@interface BMOEDNSerialization : NSObject

+(id)EDNObjectWithData:(NSData *)data error:(NSError **)error;

@end
