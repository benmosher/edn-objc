//
//  BMOEDNReader.h
//  edn-objc
//
//  Created by Ben Mosher on 8/28/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BMOEDNError.h"
#import "BMOEDNSerialization.h"

@interface BMOEDNReader : NSObject

@property (strong, readonly, nonatomic) NSDictionary * transmogrifiers;

-(instancetype)initWithOptions:(BMOEDNReadingOptions)options;
-(instancetype)initWithOptions:(BMOEDNReadingOptions)options
               transmogrifiers:(NSDictionary *)transmogrifiers;

// TODO: take an index OR take the data in the initializer
// and do a -parseNextObject-type deal
// Today, it will only parse the "first" object in the data
-(id)parse:(NSData *)data error:(NSError **)error;

@end
