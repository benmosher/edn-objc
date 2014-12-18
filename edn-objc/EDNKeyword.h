//
//  EDNKeyword.h
//  edn-objc
//
//  Created by Ben Mosher on 8/24/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EDNSymbol.h"

@interface EDNKeyword : EDNSymbol

+(EDNKeyword *) keywordWithNamespace:(NSString *)ns name:(NSString *)name;
+(EDNKeyword *) keywordWithName:(NSString *)name;

-(BOOL)isEqualToKeyword:(EDNKeyword *)object;

@end
