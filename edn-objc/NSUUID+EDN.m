//
//  NSUUID+EDN.m
//  edn-objc
//
//  Created by Ben Mosher on 8/30/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "NSUUID+EDN.h"
#import "EDNTaggedElement.h"
@implementation NSUUID (EDN)

+(void)load {
    EDNRegisterClass([NSUUID class]);
}

+(EDNSymbol *)ednTag {
    static dispatch_once_t onceToken;
    static EDNSymbol * tag;
    dispatch_once(&onceToken, ^{
        tag = [EDNSymbol symbolWithNamespace:nil name:@"uuid"];
    });
    return tag;
}

-(EDNTaggedElement *)ednRepresentation {
    return [EDNTaggedElement elementWithTag:[NSUUID ednTag] element:self.UUIDString];
}

// TODO: to except or not to except
+(instancetype)objectWithEdnRepresentation:(EDNTaggedElement *)taggedElement
                                     error:(NSError **)error {
    if (![taggedElement.tag isEqual:[self ednTag]]
        || ![taggedElement.element isKindOfClass:[NSString class]]){
        if (error != NULL)
            *error = EDNErrorMessage(EDNErrorInvalidData, @"'uuid'-tagged element must be a single string.");
        return nil;
    }
    return [[NSUUID alloc] initWithUUIDString:[taggedElement element]];
}

@end
