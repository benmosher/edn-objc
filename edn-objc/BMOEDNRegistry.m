//
//  BMOEDNRegistry.m
//  edn-objc
//
//  Created by Ben Mosher on 8/30/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "BMOEDNRegistry.h"
#import <CoreFoundation/CFDictionary.h>
#import <dispatch/once.h>
#import <objc/runtime.h>
#import "BMOEDNRepresentation.h"
#import "BMOEDNSymbol.h"

// the registry!
static CFMutableDictionaryRef TagClassMap;

void BMOEDNRegisterClass(Class clazz) {
    // check whether we should bother
    if (!class_conformsToProtocol(clazz, @protocol(BMOEDNRepresentation)))
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

Class BMOEDNRegisteredClassForTag(BMOEDNSymbol *tag) {
    if (TagClassMap == NULL) return nil;
    return CFDictionaryGetValue(TagClassMap, (__bridge const void *)(tag));
}

