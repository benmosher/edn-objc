//
//  BMOEDNTaggedObject.m
//  edn-objc
//
//  Created by Ben Mosher on 8/29/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "BMOEDNTaggedElement.h"

@implementation BMOEDNTaggedElement 

-(instancetype)initWithTag:(BMOEDNSymbol *)tag element:(id)element {
    
    // subclasses should not be used for tags
    if (![tag isMemberOfClass:[BMOEDNSymbol class]]) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Tagged element tag symbol may not be subclass of BMOEDNSymbol." userInfo:nil];
    }
    
    // tagged elements should not tag tagged elements
    if ([element isKindOfClass:[BMOEDNTaggedElement class]]) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Tagged element may not represent a tagged element as the root element." userInfo:nil];
    }
    
    if (self = [super init]) {
        _tag = tag;
        _element = element;
    }
    return self;
}

+(BMOEDNTaggedElement *)elementWithTag:(BMOEDNSymbol *)tag element:(id)element {
    return [[BMOEDNTaggedElement alloc] initWithTag:tag element:element];
}

@end
