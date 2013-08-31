//
//  BMOEDNWriter.h
//  edn-objc
//
//  Created by Ben Mosher on 8/28/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMOEDNWriter : NSObject

-(instancetype)initWithTransmogrifiers:(NSDictionary *)transmogrifiers;

@property (strong, readonly, nonatomic) NSDictionary * transmogrifiers;

// TODO: write into (or append to) an existing NSData?
-(NSData *)writeToData:(id)obj error:(NSError **)error;
-(NSString *)writeToString:(id)obj error:(NSError **)error;
@end
