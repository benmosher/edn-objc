//
//  BMOEDNUnarchiver.h
//  edn-objc
//
//  Created by Ben Mosher on 7/13/14.
//  Copyright (c) 2014 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BMOEDNTaggedElement.h"

@interface BMOEDNUnarchiver : NSCoder

-(instancetype) initForReadingWithTaggedElement:(BMOEDNTaggedElement *)data;

-(id)decodeRootObject;

@end
