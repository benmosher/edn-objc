//
//  EDNError.h
//  edn-objc
//
//  Created by Ben Mosher on 8/28/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#ifndef edn_objc_EDNError_h
#define edn_objc_EDNError_h

typedef enum : NSInteger  {
    EDNErrorNone = 0,
    EDNErrorNoData,
    EDNErrorInvalidData,
    EDNErrorUnexpectedEndOfData,
} EDNErrorCode;

FOUNDATION_EXPORT NSString *const EDNErrorDomain;
FOUNDATION_EXPORT NSString *const EDNException;

#define EDNErrorMessage(errCode,message) ([NSError errorWithDomain:EDNErrorDomain code:(errCode) userInfo:@{NSLocalizedFailureReasonErrorKey:(message)}])
#define EDNErrorMessageAssign(pointer, errCode, message) if (pointer) *pointer = EDNErrorMessage(errCode, message)
#endif
