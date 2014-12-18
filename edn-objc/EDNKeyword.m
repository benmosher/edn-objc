//
//  EDNKeyword.m
//  edn-objc
//
//  Created by Ben Mosher on 8/24/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "EDNKeyword.h"

@implementation EDNKeyword

+(EDNKeyword *)keywordWithNamespace:(NSString *)ns name:(NSString *)name {
    return [[EDNKeyword alloc] initWithNamespace:ns name:name];
}

+(EDNKeyword *)keywordWithName:(NSString *)name {
    return [[EDNKeyword alloc] initWithNamespace:nil name:name];
}

-(BOOL)isEqual:(id)object {
    if (object == self) return YES;
    if (![object isMemberOfClass:[EDNKeyword class]]) return NO;
    return [self isEqualToKeyword:(EDNKeyword *)object];
}

-(BOOL)isEqualToKeyword:(EDNKeyword *)object {
    return [super isEqualToSymbol:object];
}

-(NSString *)description {
    return [@":" stringByAppendingString:[super description]];
}

@end
