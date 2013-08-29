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

-(id)parse:(NSData *)data withError:(NSError **)error;

@end
