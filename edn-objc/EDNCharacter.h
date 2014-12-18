//
//  EDNCharacter.h
//  edn-objc
//
//  Created by Ben Mosher on 9/7/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 edn wrapper around unichar.
 */
@interface EDNCharacter : NSObject

@property (nonatomic, readonly) unichar unicharValue;

-(instancetype)initWithUnichar:(unichar)unicharr;

+(instancetype)characterWithUnichar:(unichar)unicharr;

-(BOOL)isEqualToCharacter:(EDNCharacter *)character;

@end
