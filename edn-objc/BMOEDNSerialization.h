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
    // TODO: enforce
    BMOEDNReadingLazyParsing = (1UL << 1),
};

@interface BMOEDNSerialization : NSObject

/**
 If BMOEDNReadingMultipleObjects is asserted, returned object
 is id<NSFastEnumeration>. Else, the first valid EDN object in
 the data is returned, or nil if no valid data.
 */
+(id)EDNObjectWithData:(NSData *)data options:(BMOEDNReadingOptions)options error:(NSError **)error;
/**
 @param transmogrifiers: a dictionary of EDNSymbols to BMOEDNTransmogrifier
 blocks that turn the provided edn tagged element into some native object.
 */
+(id)EDNObjectWithData:(NSData *)data
       transmogrifiers:(NSDictionary *)transmogrifiers
               options:(BMOEDNReadingOptions)options
                 error:(NSError **)error;


+(NSData *)dataWithEDNObject:(id)obj error:(NSError **)error;
+(NSData *)dataWithEDNObject:(id)obj
             transmogrifiers:(NSDictionary *)transmogrifiers
                       error:(NSError **)error;

+(NSString *)stringWithEDNObject:(id)obj error:(NSError **)error;
+(NSString *)stringWithEDNObject:(id)obj
                 transmogrifiers:(NSDictionary *)transmogrifiers
                           error:(NSError **)error;


@end
