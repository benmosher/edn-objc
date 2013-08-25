//
//  edn_objcTests.m
//  edn-objcTests
//
//  Created by Ben Mosher on 8/24/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "edn_objcTests.h"
#import "BMOEDNSerialization.h"
#import "BMOEDNList.h"

@implementation edn_objcTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testParseStrings
{
    STAssertEqualObjects([BMOEDNSerialization EDNObjectWithData:[@"\"whee\"" dataUsingEncoding:NSUTF8StringEncoding] error:NULL], @"whee", @"");
    STAssertEqualObjects([BMOEDNSerialization EDNObjectWithData:[@"\"I have a \\\"mid-quoted\\\" string in me.\\nAnd two lines.\\r\\nWindows file: \\\"C:\\\\a file.txt\\\"\"" dataUsingEncoding:NSUTF8StringEncoding] error:NULL], @"I have a \"mid-quoted\" string in me.\nAnd two lines.\r\nWindows file: \"C:\\a file.txt\"", @"");
}

- (void)testParseLiterals
{
    STAssertEquals([BMOEDNSerialization EDNObjectWithData:[@"true" dataUsingEncoding:NSUTF8StringEncoding] error:NULL], (__bridge NSNumber *)kCFBooleanTrue, @"");
    STAssertEquals([BMOEDNSerialization EDNObjectWithData:[@"false" dataUsingEncoding:NSUTF8StringEncoding] error:NULL], (__bridge NSNumber *)kCFBooleanFalse, @"");
    STAssertEqualObjects([BMOEDNSerialization EDNObjectWithData:[@"nil" dataUsingEncoding:NSUTF8StringEncoding] error:NULL], [NSNull null], @"");
}

- (void)testParseNumerals
{
    STAssertEqualObjects([BMOEDNSerialization EDNObjectWithData:[@"0" dataUsingEncoding:NSUTF8StringEncoding] error:NULL], [NSNumber numberWithInt:0], @"");
    STAssertEqualObjects([BMOEDNSerialization EDNObjectWithData:[@"1.1E1" dataUsingEncoding:NSUTF8StringEncoding] error:NULL], [NSNumber numberWithDouble:11.0], @"");
}

- (void)testParseVectors
{
    STAssertEqualObjects([BMOEDNSerialization EDNObjectWithData:[@"[]" dataUsingEncoding:NSUTF8StringEncoding] error:NULL], @[], @"");
    STAssertEqualObjects([BMOEDNSerialization EDNObjectWithData:[@"[ 1 ]" dataUsingEncoding:NSUTF8StringEncoding] error:NULL], @[@1], @"");
    id array = @[@1, @2];
    STAssertEqualObjects([BMOEDNSerialization EDNObjectWithData:[@"[ 1 2 ]" dataUsingEncoding:NSUTF8StringEncoding] error:NULL], array, @"");
    array = @[@[@1, @2], @[@3], @[]];
    STAssertEqualObjects([BMOEDNSerialization EDNObjectWithData:[@"[ [ 1, 2 ], [ 3 ], [] ]" dataUsingEncoding:NSUTF8StringEncoding] error:NULL], array, @"");
}

- (void)testParseLists
{
    BMOEDNList *list = (BMOEDNList *)[BMOEDNSerialization EDNObjectWithData:[@"()" dataUsingEncoding:NSUTF8StringEncoding] error:NULL];
    STAssertTrue([list isKindOfClass:[BMOEDNList class]], @"");
    STAssertNil([list head], @"");
    
    list = (BMOEDNList *)[BMOEDNSerialization EDNObjectWithData:[@"( 1 2 3 4 5 )" dataUsingEncoding:NSUTF8StringEncoding] error:NULL];
    STAssertTrue([list isKindOfClass:[BMOEDNList class]], @"");
    STAssertNotNil([list head], @"");
    BMOEDNConsCell *current = list.head;
    int i = 1;
    do {
        STAssertEqualObjects(current.first,@(i++), @"");
    } while ((current = current.rest) != nil);
}

@end
