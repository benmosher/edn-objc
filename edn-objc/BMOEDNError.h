//
//  BMOEDNError.h
//  edn-objc
//
//  Created by Ben Mosher on 8/28/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#ifndef edn_objc_BMOEDNError_h
#define edn_objc_BMOEDNError_h

typedef enum  {
    BMOEDNSerializationErrorCodeNone = 0,
    BMOEDNSerializationErrorCodeNoData,
    BMOEDNSerializationErrorCodeInvalidData,
    BMOEDNSerializationErrorCodeUnexpectedEndOfData,
} BMOEDNSerializationErrorCode;

FOUNDATION_EXPORT NSString *const BMOEDNErrorDomain;
FOUNDATION_EXPORT NSString *const BMOEDNException;

// TODO: use message version
#define BMOEDNError(errCode) ([NSError errorWithDomain:BMOEDNErrorDomain code:errCode userInfo:nil])
#define BMOEDNErrorMessage(errCode,message) BMOEDNError(errCode)

#endif
