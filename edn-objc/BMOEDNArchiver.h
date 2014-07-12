//
//  BMOEDNArchiver.h
//  edn-objc
//
//  Created by Ben Mosher on 7/11/14.
//  Copyright (c) 2014 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMOEDNArchiver : NSCoder

-(instancetype) initForWritingWithMutableData:(NSMutableData *)data;

+(NSData *)archivedDataWithRootObject:(id)object;

@end
