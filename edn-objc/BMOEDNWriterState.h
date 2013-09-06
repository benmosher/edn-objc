//
//  BMOEDNWriterState.h
//  edn-objc
//
//  Created by Ben Mosher on 9/2/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMOEDNWriterState : NSObject {
    NSOutputStream *_stream;
    
    // for memory streams
    dispatch_once_t _exported;
    NSData *_data;
    
}
@property (strong, nonatomic) NSError *error;
@property (nonatomic) BOOL exportable;

-(instancetype)initWithStream:(NSOutputStream *)stream;

-(void)appendString:(NSString *)string;
-(void)write:(const uint8_t *)buffer maxLength:(NSUInteger)len;

-(NSData *)writtenData;
-(NSString *)writtenString;

@end
