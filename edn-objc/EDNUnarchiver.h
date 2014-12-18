//
//  EDNUnarchiver.h
//  edn-objc
//
//  Created by Ben Mosher on 7/13/14.
//  Copyright (c) 2014 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EDNTaggedElement.h"

@interface EDNUnarchiver : NSCoder

-(instancetype) initForReadingWithTaggedElement:(EDNTaggedElement *)data;

-(id)decodeRootObject;

@end
