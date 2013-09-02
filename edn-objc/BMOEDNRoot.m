//
//  BMOEDNRoot.m
//  edn-objc
//
//  Created by Ben Mosher on 8/31/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "BMOEDNRoot.h"

@interface BMOEDNRootEnumerator : NSEnumerator {
    BMOEDNRoot *_root;
}

@property (assign, atomic) NSUInteger currentIndex;

-(instancetype)initWithBMOEDNRoot:(BMOEDNRoot *)root;

@end

@implementation BMOEDNRootEnumerator

-(instancetype)initWithBMOEDNRoot:(BMOEDNRoot *)root {
    if (self = [super init]) {
        _root = root;
        _currentIndex = 0;
    }
    return self;
}

@end

@implementation BMOEDNRoot

-(instancetype)initWithEnumerable:(id<NSObject,NSFastEnumeration>)elements {
    if (self = [super init]) {
        _elements = elements;
        if ([elements isKindOfClass:[NSEnumerator class]]) {
            _realized = [NSMutableArray new];
            _realizationQueue = dispatch_queue_create("BMOEDNRootRealizationQueue", DISPATCH_QUEUE_SERIAL);
        }
    }
    return self;
}

-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    if ([_elements isKindOfClass:[NSEnumerator class]]) { // do all this goofiness for realization
        if (state->state == 0) {
            state->state = 1;
            state->mutationsPtr = &mutationMarker;
            state->extra[0] = 0; // current index of enumeration (to check for realization)
        }
        __block NSUInteger read = 0;
        // all enumerations occur in the serial queue for safety
        dispatch_sync(_realizationQueue, ^{
            
            // fill in the buffer from _realized as much as possible,
            // and ensure that state->extra[0] points to the current position
            while (read < len && (_realized.count > state->extra[0])) {
                buffer[read++] = _realized[state->extra[0]++];
            }
            
            // load from enumerator, if needed
            id nextObject;
            while (read < len && (nextObject = [(NSEnumerator *)_elements nextObject])) {
                buffer[read++] = nextObject;
                [_realized addObject:nextObject];
                state->extra[0]++;
            }
            return;
        });
        state->itemsPtr = buffer;
        return read;
        
    } else // ignore all this realization foolishness
        return [_elements countByEnumeratingWithState:state objects:buffer count:len];
    
}

-(NSUInteger)hash {
    return [_elements hash];
}

-(BOOL)isEqual:(id)object {
    if (object == self) return true;
    if (object == nil) return false;
    if (![object isMemberOfClass:[BMOEDNRoot class]]) return false;
    return [_elements isEqual:((BMOEDNRoot *)object)->_elements];
}



@end
