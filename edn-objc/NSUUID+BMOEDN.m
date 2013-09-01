//
//  NSUUID+BMOEDN.m
//  edn-objc
//
//  Created by Ben Mosher on 8/30/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "NSUUID+BMOEDN.h"
#import "BMOEDNTaggedElement.h"
@implementation NSUUID (BMOEDN)

+(void)load {
    BMOEDNRegisterClass([NSUUID class]);
}

+(BMOEDNSymbol *)EDNTag {
    static dispatch_once_t onceToken;
    static BMOEDNSymbol * tag;
    dispatch_once(&onceToken, ^{
        tag = [BMOEDNSymbol symbolWithNamespace:nil name:@"uuid"];
    });
    return tag;
}

-(BMOEDNTaggedElement *)EDNRepresentation {
    return [BMOEDNTaggedElement elementWithTag:[NSUUID EDNTag] element:self.UUIDString];
}

// TODO: to except or not to except
+(instancetype)objectWithEDNRepresentation:(BMOEDNTaggedElement *)taggedElement
                                     error:(NSError **)error {
    if (![taggedElement.tag isEqual:[self EDNTag]]
        || ![taggedElement.element isKindOfClass:[NSString class]]){
        if (error != NULL)
            *error = BMOEDNErrorMessage(BMOEDNErrorInvalidData, @"'uuid'-tagged element must be a single string.");
        return nil;
    }
    return [[NSUUID alloc] initWithUUIDString:[taggedElement element]];
}

@end
