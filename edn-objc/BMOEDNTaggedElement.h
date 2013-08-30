//
//  BMOEDNTaggedObject.h
//  edn-objc
//
//  Created by Ben Mosher on 8/29/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BMOEDNSymbol.h"
@interface BMOEDNTaggedElement : NSObject

@property (strong, nonatomic, readonly) BMOEDNSymbol * tag;
@property (strong, nonatomic, readonly) id element;

-(instancetype)initWithTag:(BMOEDNSymbol *)tag element:(id)element;

@end
