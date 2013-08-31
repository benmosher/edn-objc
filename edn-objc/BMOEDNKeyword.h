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

+(BMOEDNKeyword *) keywordWithNamespace:(NSString *)ns name:(NSString *)name;

-(BOOL)isEqualToKeyword:(BMOEDNKeyword *)object;

@end
