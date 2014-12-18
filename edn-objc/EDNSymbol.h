//
//  EDNSymbol.h
//  edn-objc
//
//  Created by Ben Mosher on 8/25/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EDNSymbol : NSObject <NSCopying>

@property (strong, nonatomic, readonly) NSString *ns;
@property (strong, nonatomic, readonly) NSString *name;

-(instancetype)initWithNamespace:(NSString *)ns
                            name:(NSString *)name;

+(EDNSymbol *)symbolWithNamespace:(NSString *)ns
                                name:(NSString *)name;

/**
 * Do not use this method to compare to any subclasses.
 */
-(BOOL)isEqualToSymbol:(EDNSymbol *)object;

@end
