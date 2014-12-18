//
//  EDNRegistry.m
//  edn-objc
//
//  Created by Ben Mosher on 8/30/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "EDNRegistry.h"
#import <CoreFoundation/CFDictionary.h>
#import <dispatch/once.h>
#import <objc/runtime.h>
#import "EDNRepresentation.h"
#import "EDNSymbol.h"

// the registry!
static CFMutableDictionaryRef TagClassMap;

void EDNRegisterClass(Class clazz) {
    // check whether we should bother
    if (!class_conformsToProtocol(clazz, @protocol(EDNRepresentation)))
        return; // nothing we can do
    
    // lazily initialize the registry
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        TagClassMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    });
    
    // grab and add the tag
    id tag = [clazz ednTag];
    CFDictionaryAddValue(TagClassMap, (__bridge const void *)(tag), (__bridge const void *)(clazz));
}

Class EDNRegisteredClassForTag(EDNSymbol *tag) {
    if (TagClassMap == NULL) return nil;
    return CFDictionaryGetValue(TagClassMap, (__bridge const void *)(tag));
}

