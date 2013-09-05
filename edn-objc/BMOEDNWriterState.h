//
//  BMOEDNWriterState.h
//  edn-objc
//
//  Created by Ben Mosher on 9/2/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMOEDNWriterState : NSObject {
    NSUInteger _currentIndex;
    NSMutableString *_mutableString;
}
@property (strong, nonatomic) NSError *error;

-(instancetype)init;

-(void)appendString:(NSString *)string;

-(NSData *)writtenData;
-(NSString *)writtenString;

@end
