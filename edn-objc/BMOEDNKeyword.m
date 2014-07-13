//
//  BMOEDNKeyword.m
//  edn-objc
//
//  Created by Ben Mosher on 8/24/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "BMOEDNKeyword.h"

@implementation BMOEDNKeyword

+(BMOEDNKeyword *)keywordWithNamespace:(NSString *)ns name:(NSString *)name {
    return [[BMOEDNKeyword alloc] initWithNamespace:ns name:name];
}

+(BMOEDNKeyword *)keywordWithName:(NSString *)name {
    return [[BMOEDNKeyword alloc] initWithNamespace:nil name:name];
}

-(BOOL)isEqual:(id)object {
    if (object == self) return YES;
    if (![object isMemberOfClass:[BMOEDNKeyword class]]) return NO;
    return [self isEqualToKeyword:(BMOEDNKeyword *)object];
}

-(BOOL)isEqualToKeyword:(BMOEDNKeyword *)object {
    return [super isEqualToSymbol:object];
}

-(NSString *)description {
    return [@":" stringByAppendingString:[super description]];
}

@end
