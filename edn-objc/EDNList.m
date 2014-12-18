//
//  EDNConsCell.m
//  edn-objc
//
//  Created by Ben Mosher on 8/25/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "EDNList.h"

@implementation EDNConsCell

-(BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[EDNConsCell class]]) return NO;
    return [self isEqualToConsCell:(EDNConsCell *)object];
}

-(BOOL)isEqualToConsCell:(EDNConsCell *)object {
    return [self.first isEqual:object.first]
        // direct comparison knocks out both nil or reference equality
        && ((self.rest == object.rest) || [self.rest isEqual:object.rest]);
}

-(NSUInteger)hash {
    return [self.first hash] ^ ([self.rest hash] * 17);
}

@end


// TODO: fast enumeration, recursive equality testing
// TODO: immutability + XOR'd hashes of cons cell contents? for set membership?
@implementation EDNList

-(NSUInteger)hash {
    if (!_hashed) {
        _hash = [self.head hash];
        _hashed = YES;
    }
    return _hash;
}

-(BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[EDNList class]]) return NO;
    return [self isEqualToList:(EDNList *)object];
}

-(BOOL)isEqualToList:(EDNList *)list {
    return _count == list->_count && [self.head isEqualToConsCell:list.head];
}

-(id)copyWithZone:(NSZone *)zone {
    return self;
}

#pragma mark - Fast enumeration

// implementation adapted from
// http://www.mikeash.com/pyblog/friday-qa-2010-04-16-implementing-fast-enumeration.html
// and
// http://blog.bignerdranch.com/1073-fast-enumeration-part-3/
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    
    assert(sizeof(EDNConsCell *) <= sizeof(unsigned long));
    
    if(state->state == 0)
    {
        // state 0 means it's the first call, so get things set up
        // we won't try to detect mutations, so make mutationsPtr
        // point somewhere that's guaranteed not to change
        state->mutationsPtr = &_count;
        
        // set up extra[0] to point to the head to start in the right place
        state->extra[0] = (unsigned long)_head;
        
        // and update state to indicate that enumeration has started
        state->state = 1;
    }
    
    // pull the node out of extra[0]
    EDNConsCell *currentCell = (__bridge EDNConsCell *)((void *)state->extra[0]);
    
    // iterate while there's space in the buffer and there are more cells
    NSUInteger i;
    for (i = 0; currentCell != nil && i < len; i++) {
        buffer[i] = currentCell->_first;
        currentCell = currentCell->_rest;
    }
    // point the buffer
    state->itemsPtr = buffer;
    
    // update extra[0]
    state->extra[0] = (unsigned long)currentCell;
    
    return i;
}

#pragma mark - Push and pop

-(EDNList *)listByPushing:(id)head {
    // new list and head cell
    EDNList *newList = [[EDNList alloc] init];
    EDNConsCell *newHead = [[EDNConsCell alloc] init];
    
    newHead->_first = head;
    newHead->_rest = _head;
    newList->_count = _count + 1;
    newList->_head = newHead;
    return newList;
}

-(EDNList *)listByPopping {
    // new list
    EDNList *newList = [[EDNList alloc] init];
    
    newList->_head = _head->_rest;
    newList->_count = _count - 1;
    
    return newList;
}

@end
