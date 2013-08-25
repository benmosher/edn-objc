//
//  edn_objcTests.m
//  edn-objcTests
//
//  Created by Ben Mosher on 8/24/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "edn_objcTests.h"
#import "BMOEDNSerialization.h"

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

- (void) testParseStrings
{
    STAssertEqualObjects([BMOEDNSerialization EDNObjectWithData:[@"\"whee\"" dataUsingEncoding:NSUTF8StringEncoding] error:NULL], @"whee", @"");
    STAssertEqualObjects([BMOEDNSerialization EDNObjectWithData:[@"\"I have a \\\"mid-quoted\\\" string in me.\\nAnd two lines.\\r\\nWindows file: \\\"C:\\\\a file.txt\\\"\"" dataUsingEncoding:NSUTF8StringEncoding] error:NULL], @"I have a \"mid-quoted\" string in me.\nAnd two lines.\r\nWindows file: \"C:\\a file.txt\"", @"");
}

@end
