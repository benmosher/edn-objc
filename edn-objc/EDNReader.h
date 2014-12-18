//
//  EDNReader.h
//  edn-objc
//
//  Created by Ben Mosher on 8/28/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EDNError.h"
#import "EDNSerialization.h"

@interface EDNReader : NSObject

@property (strong, readonly, nonatomic) NSDictionary * transmogrifiers;

-(instancetype)initWithOptions:(EDNReadingOptions)options;
-(instancetype)initWithOptions:(EDNReadingOptions)options
               transmogrifiers:(NSDictionary *)transmogrifiers;

-(id)parse:(NSData *)data error:(NSError **)error;
-(id)parseStream:(NSInputStream *)data error:(NSError **)error;
@end
