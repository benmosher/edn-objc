//
//  BMOEDNWriter.h
//  edn-objc
//
//  Created by Ben Mosher on 8/28/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMOEDNWriter : NSObject

-(instancetype)initWithResolvers:(NSDictionary *)resolvers;

@property (strong, readonly, nonatomic) NSDictionary * resolvers;

// TODO: write into an existing NSData?
-(NSData *)write:(id)obj error:(NSError **)error;

@end
