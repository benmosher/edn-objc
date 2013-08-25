//
//  BMOEDNKeyword.h
//  edn-objc
//
//  Created by Ben Mosher on 8/24/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BMOEDNNamespace.h"

@interface BMOEDNKeyword : NSObject

@property (strong,nonatomic) BMOEDNNamespace *namespace;
@property (strong,nonatomic) NSString *symbol;

#if __has_feature(objc_instancetype)
+(instancetype)keywordMatchingString:(NSString *)string;
#else
+(id)keywordMatchingString:(NSString *)string;
#endif

@end
