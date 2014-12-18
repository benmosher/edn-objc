//
//  NSDate+EDN.m
//  edn-objc
//
//  Created by Ben Mosher on 8/30/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "NSDate+EDN.h"

@implementation NSDate (EDN)

+(void)load {
    EDNRegisterClass([NSDate class]);
}

+(EDNSymbol *)ednTag {
    static EDNSymbol *tag;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tag = [EDNSymbol symbolWithNamespace:nil name:@"inst"];
    });
    return tag;
}

NSDateFormatter *EDNCreateInstDateFormatter(void) {
    static NSString * rfc3339 = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SS'Z'";
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [df setDateFormat:rfc3339];
    [df setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    return df;
}

+(instancetype)objectWithEdnRepresentation:(EDNTaggedElement *)taggedElement
                                     error:(NSError **)error{
    
    if (![taggedElement.tag isEqualToSymbol:[self ednTag]]){
        if (error != NULL) {
            *error = EDNErrorMessage(EDNErrorInvalidData,@"'inst'-tagged resolver called for non-'inst' tag.");
        }
        return nil;
    }
    if (![taggedElement.element isKindOfClass:[NSString class]]) {
        if (error != NULL) {
            *error = EDNErrorMessage(EDNErrorInvalidData,@"'inst'-tagged objects must be an RFC3339-formatted string.");
        }
        return nil;
    } else {
        NSDateFormatter *df = EDNCreateInstDateFormatter();
        NSDate *date = [df dateFromString:taggedElement.element];
        if (date == nil && error != NULL) {
            *error = EDNErrorMessage(EDNErrorInvalidData,@"'inst'-tagged object must be an RFC3339-formatted string.");
        }
        return date;
    }
}

-(EDNTaggedElement *)ednRepresentation {
    NSDateFormatter *df = EDNCreateInstDateFormatter();
    return [EDNTaggedElement elementWithTag:[NSDate ednTag] element:[df stringFromDate:self]];
}


@end
