//
//  edn_objc.h
//  edn-objc
//
//  Created by Ben Mosher on 8/24/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>

// thanks, http://nshipster.com/ns_enum-ns_options/
typedef NS_OPTIONS(NSUInteger, BMOEDNReadingOptions) {
    BMOEDNReadingMultipleObjects = (1UL << 0),
    // lazy parsing implies multiple objects
    BMOEDNReadingLazyParsing = (1UL << 1),
};

@interface BMOEDNSerialization : NSObject

#pragma mark - NSData reading methods

/**
 If BMOEDNReadingMultipleObjects is asserted, returned object
 is id<NSFastEnumeration>. Else, the first valid EDN object in
 the data is returned, or nil if no valid data.
 */
+(id)EDNObjectWithData:(NSData *)data
               options:(BMOEDNReadingOptions)options
                 error:(NSError **)error;
/**
 @param transmogrifiers: a dictionary of EDNSymbols to BMOEDNTransmogrifier
 blocks that turn the provided edn tagged element into some native object.
 */
+(id)EDNObjectWithData:(NSData *)data
       transmogrifiers:(NSDictionary *)transmogrifiers
               options:(BMOEDNReadingOptions)options
                 error:(NSError **)error;

#pragma mark - NSInputStream reading methods

/**
 If BMOEDNReadingMultipleObjects is asserted, returned object
 is id<NSFastEnumeration>. Else, the first valid EDN object in
 the data is returned, or nil if no valid data.
 
 If lazy reading is not specified, this method may block until a full
 valid object is returned, the stream is closed, or an error is encountered.
 */
+(id)EDNObjectWithStream:(NSInputStream *)data
                 options:(BMOEDNReadingOptions)options
                   error:(NSError **)error;
/**
 @param transmogrifiers: a dictionary of EDNSymbols to BMOEDNTransmogrifier
 blocks that turn the provided edn tagged element into some native object.
 */
+(id)EDNObjectWithStream:(NSInputStream *)data
         transmogrifiers:(NSDictionary *)transmogrifiers
                 options:(BMOEDNReadingOptions)options
                   error:(NSError **)error;

#pragma mark - NSData writing methods

+(NSData *)dataWithEDNObject:(id)obj error:(NSError **)error;
+(NSData *)dataWithEDNObject:(id)obj
             transmogrifiers:(NSDictionary *)transmogrifiers
                       error:(NSError **)error;

+(NSString *)stringWithEDNObject:(id)obj error:(NSError **)error;
+(NSString *)stringWithEDNObject:(id)obj
                 transmogrifiers:(NSDictionary *)transmogrifiers
                           error:(NSError **)error;

#pragma mark - NSStream writing methods

+(void)writeEDNObject:(id)obj
             toStream:(NSOutputStream *)stream
                error:(NSError **)error;

+(void)writeEDNObject:(id)obj
             toStream:(NSOutputStream *)stream
      transmogrifiers:(NSDictionary *)transmogrifiers
                error:(NSError **)error;
@end
