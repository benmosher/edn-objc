//
//  BMOEDNKeyword.h
//  edn-objc
//
//  Created by Ben Mosher on 8/24/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BMOEDNSymbol.h"

@interface BMOEDNKeyword : BMOEDNSymbol

-(BOOL)isEqualToKeyword:(BMOEDNKeyword *)object;

@end
