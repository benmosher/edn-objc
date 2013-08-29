//
//  BMOEDNParser.h
//  edn-objc
//
//  Created by Ben Mosher on 8/28/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BMOEDNDefines.pch"

@interface BMOEDNReader : NSObject

-(instancetype)initWithResolvers:(NSDictionary *)resolvers;

@property (strong, readonly, nonatomic) NSDictionary * resolvers;

// TODO: take an index OR take the data in the initializer
// and do a -parseNextObject-type deal
// Today, it will only parse the "first" object in the data
-(id)parse:(NSData *)data error:(NSError **)error;

@end
