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

-(instancetype)initWithEnumerator:(NSEnumerator *)enumerator {
    if (self = [super init]) {
        _enumerator = enumerator;
        _realized = [NSMutableArray new];
        _realizationQueue = dispatch_queue_create("BMOEDNRootRealizationQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

-(instancetype)initWithArray:(NSArray *)array {
    if (self = [super init]) {
        _realized = [array copy];
    }
    return self;
}


-(id)objectAtIndex:(NSUInteger)idx {
    // check for realization existence before locking it up
    if (_enumerator == nil || [_realized count] > idx) return [_realized objectAtIndex:idx];
    
    __block id object = nil;
    __block NSException *outOfRange = nil;
    // all enumerations occur in the serial queue (for safety)
    dispatch_sync(_realizationQueue, ^{
        if (_realized.count > idx) object = [_realized objectAtIndex:idx];
        // load from enumerator, if needed
        else {
            NSUInteger current = _realized.count;
            while (current <= idx &&
                   (object = [(NSEnumerator *)_enumerator nextObject])) {
                [(NSMutableArray *)_realized addObject:object];
                current++;
            }
            if (object == nil) _enumerator = nil;
            if (current <= idx) outOfRange = [NSException exceptionWithName:NSRangeException reason:@"Index beyond edge of range." userInfo:nil];
        }
    });
    if (outOfRange != nil) @throw outOfRange;
    return object;
}

-(id)objectAtIndexedSubscript:(NSUInteger)idx {
    return [self objectAtIndex:idx];
}

-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    if (state->state == 0) {
        state->state = 1;
        state->mutationsPtr = &mutationMarker;
        state->extra[0] = 0; // current index of enumeration (to check for realization)
        state->extra[1] = 0; // will point to internal state
    }
    if (_enumerator) { // do all this goofiness for realization

        __block NSUInteger read = 0;
        // all enumerations occur in the serial queue for safety
        dispatch_sync(_realizationQueue, ^{
            
            // fill in the buffer from _realized as much as possible,
            // and ensure that state->extra[0] points to the current position
            while (read < len && (_realized.count > state->extra[0])) {
                buffer[read++] = _realized[state->extra[0]++];
            }
            
            // load from enumerator, if needed
            id nextObject = nil;
            while (read < len && (nextObject = [(NSEnumerator *)_enumerator nextObject])) {
                buffer[read++] = nextObject;
                [(NSMutableArray *)_realized addObject:nextObject];
                state->extra[0]++;
            }
            if (nextObject == nil) _enumerator = nil;
            return;
        });
        state->itemsPtr = buffer;
        return read;
    } else if (state->extra[0] < _realized.count || state->extra[1]) {
        NSFastEnumerationState *innerState = NULL;
        if (state->extra[1]) {
            innerState = (NSFastEnumerationState *)state->extra[1];
        } else {
            innerState = calloc(1, sizeof(NSFastEnumerationState));
            state->extra[1] = (unsigned long)innerState;
        }
        NSUInteger count = [_realized countByEnumeratingWithState:innerState objects:buffer count:len];
        state->extra[0] += count;
        state->itemsPtr = innerState->itemsPtr;
        if (!count) free(innerState);
        return count;
    } else return 0;
    
}
/* need to reconsider these implementations.
-(NSUInteger)hash {
    return [_enumerator hash];
}

-(BOOL)isEqual:(id)object {
    if (object == self) return true;
    if (object == nil) return false;
    if (![object isMemberOfClass:[BMOEDNRoot class]]) return false;
    return [_enumerator isEqual:((BMOEDNRoot *)object)->_enumerator];
}
*/
//-(NSEnumerator *)objectEnumerator {}

@end
