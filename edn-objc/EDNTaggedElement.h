//
//  EDNTaggedElement.h
//  edn-objc
//
//  Created by Ben Mosher on 8/29/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EDNSymbol.h"

@interface EDNTaggedElement : NSObject

@property (strong, nonatomic, readonly) EDNSymbol * tag;
@property (strong, nonatomic, readonly) id element;

-(instancetype)initWithTag:(EDNSymbol *)tag element:(id)element;

+(EDNTaggedElement *)elementWithTag:(EDNSymbol *)tag element:(id)element;

@end
