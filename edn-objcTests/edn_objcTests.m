//
//  edn_objcTests.m
//  edn-objcTests
//
//  Created by Ben Mosher on 8/24/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "edn_objcTests.h"
#import "edn-objc.h"


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
    STAssertEqualObjects([@"\"\\\\\\\"\"" objectFromEDNString], @"\\\"", @"Backslash city.");
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
    STAssertEqualObjects([@"-2" objectFromEDNString], @(-2), @"");
    STAssertEqualObjects([@"+0" objectFromEDNString], @(0), @"");
    STAssertEqualObjects([@"10000N" objectFromEDNString], @(10000), @"");
    STAssertEqualObjects([@"1000.1M" objectFromEDNString], [NSDecimalNumber decimalNumberWithMantissa:10001 exponent:-1 isNegative:NO], @"");
}

- (void)testCMathWorksHowIExpect
{
    // word on the street is that NSIntegers are converted to NSUInteger
    // during comparison/arithmetic; if overflow wraps, the conversion
    // should not impact addition
    STAssertEquals(NSUIntegerMax+((NSInteger)-1), NSUIntegerMax-1, @"");
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
    
    list = (BMOEDNList *)[[BMOEDNSerialization EDNObjectWithData:[@"[( 1 2 3 4 5 ) 1]" dataUsingEncoding:NSUTF8StringEncoding] error:NULL] objectAtIndex:0];
    STAssertTrue([list isKindOfClass:[BMOEDNList class]], @"");
    STAssertNotNil([list head], @"");
    BMOEDNConsCell *current = list.head;
    int i = 1;
    do {
        STAssertEqualObjects(current.first,@(i++), @"");
    } while ((current = current.rest) != nil);
    
    id<NSObject> secondList = [BMOEDNSerialization EDNObjectWithData:[@"( 1 2 3 4 5 )" dataUsingEncoding:NSUTF8StringEncoding]
                                                      error:NULL];
    STAssertEqualObjects(list, secondList, @"");
    STAssertEquals(list.hash, secondList.hash, @"");
}

- (void)testComments
{
    id array = @[@1, @2];
    STAssertEqualObjects([BMOEDNSerialization EDNObjectWithData:[@"[ 1 ;; mid-array comment\n 2 ]" dataUsingEncoding:NSUTF8StringEncoding] error:NULL], array, @"");
    STAssertEqualObjects([BMOEDNSerialization EDNObjectWithData:[@"[ 1;3\n2 ]" dataUsingEncoding:NSUTF8StringEncoding] error:NULL], array, @"");
}

- (void)testDiscards
{
    id array = @[@1, @2];
    STAssertEqualObjects([BMOEDNSerialization EDNObjectWithData:[@"[ 1 #_ foo 2 ]" dataUsingEncoding:NSUTF8StringEncoding] error:NULL], array, @"");
    STAssertEqualObjects([BMOEDNSerialization EDNObjectWithData:[@"[ 1 2 #_foo ]" dataUsingEncoding:NSUTF8StringEncoding] error:NULL], array, @"");
    NSError *err = nil;
    id obj = [BMOEDNSerialization EDNObjectWithData:[@"  #_fooooo  " dataUsingEncoding:NSUTF8StringEncoding] error:&err];
    STAssertNil(obj, @"");
    // TODO: error for totally empty string?
    //STAssertNotNil(err, @"");
    //STAssertEquals(err.code, (NSInteger)BMOEDNSerializationErrorCodeNoData, @"");
    
    BMOEDNList *list = (BMOEDNList *)[BMOEDNSerialization EDNObjectWithData:[@"( 1 #_foo 2 3 4 5 #_bar)" dataUsingEncoding:NSUTF8StringEncoding] error:NULL];
    STAssertTrue([list isKindOfClass:[BMOEDNList class]], @"");
    STAssertNotNil([list head], @"");
    BMOEDNConsCell *current = list.head;
    int i = 1;
    do {
        STAssertEqualObjects(current.first,@(i++), @"");
    } while ((current = current.rest) != nil);
}

- (void)testSets
{
    STAssertEqualObjects([BMOEDNSerialization EDNObjectWithData:[@"#{}" dataUsingEncoding:NSUTF8StringEncoding] error:NULL], [NSSet setWithArray:@[]], @"");
    STAssertEqualObjects([BMOEDNSerialization EDNObjectWithData:[@"#{ 1 }" dataUsingEncoding:NSUTF8StringEncoding] error:NULL], [NSSet setWithArray:@[@1]], @"");
    id set = [NSSet setWithArray:@[@1, @2]];
    STAssertEqualObjects([BMOEDNSerialization EDNObjectWithData:[@"#{ 1 2 }" dataUsingEncoding:NSUTF8StringEncoding] error:NULL], set, @"");
    STAssertNil([@"#{ 1 1 2 3 5 }" objectFromEDNString], @"Repeated set members should fail.");
}

- (void)testMaps
{
    id map = @{
        @"one":@(1),
        [BMOEDNSerialization EDNObjectWithData:[@"( 1 2 )" dataUsingEncoding:NSUTF8StringEncoding]
                                         error:NULL]:@"two",
        @"three":@"surprise!"};
    STAssertEqualObjects([BMOEDNSerialization EDNObjectWithData:[@"{\"one\" 1 ( 1 2 ) \"two\" \"three\" \"surprise!\"}" dataUsingEncoding:NSUTF8StringEncoding] error:NULL], map, @"");
    
    STAssertEqualObjects([@"{ :one one :two + :three - :four \"four\" }" objectFromEDNString],
                         (@{
                          [@":one" objectFromEDNString]: [@"one" objectFromEDNString],
                          [@":two" objectFromEDNString]: [[BMOEDNSymbol alloc] initWithNamespace:nil name:@"+"],
                          [@":three" objectFromEDNString]: [[BMOEDNSymbol alloc] initWithNamespace:nil name:@"-"],
                          [@":four" objectFromEDNString]: @"four"
                          }), @"");
    STAssertNil([@"{:one 1 :one \"one\"}" objectFromEDNString],@"Repeat keys should fail.");
}

- (void)testStringCategory {
    STAssertEqualObjects([@"\"string\"" objectFromEDNString], @"string", @"");
    STAssertEqualObjects([@"[ 1 2 3 ]" objectFromEDNString], (@[(@1),(@2),(@3)]), @"");
}

- (void)testKeywords
{
    STAssertEqualObjects([@":keyword" objectFromEDNString], [[BMOEDNKeyword alloc] initWithNamespace:nil name:@"keyword"], @"");
    STAssertEqualObjects([@":namespaced/keyword" objectFromEDNString], [[BMOEDNKeyword alloc] initWithNamespace:@"namespaced" name:@"keyword"], @"");
    STAssertThrows([[BMOEDNKeyword alloc] initWithNamespace:@"something" name:nil], @"");
    STAssertNil([@":" objectFromEDNString],@"");
    STAssertNil([@":/nonamespace" objectFromEDNString], @"");
    STAssertNil([@":so/many/names/paces" objectFromEDNString], @"");
    STAssertFalse([[@":keywordsymbol" objectFromEDNString] isEqual:[@"keywordsymbol" objectFromEDNString]], @"");
    STAssertFalse([[@"symbolkeyword" objectFromEDNString] isEqual:[@":symbolkeyword" objectFromEDNString]], @"");
}

- (void)testSymbols
{
    STAssertEqualObjects([@"symbol" objectFromEDNString], [[BMOEDNSymbol alloc] initWithNamespace:nil name:@"symbol"], @"");
    STAssertEqualObjects([@"namespaced/symbol" objectFromEDNString], [[BMOEDNSymbol alloc] initWithNamespace:@"namespaced" name:@"symbol"], @"");
    STAssertThrows([[BMOEDNSymbol alloc] initWithNamespace:@"something" name:nil], @"");
    STAssertNil([@"/nonamespace" objectFromEDNString], @"");
    STAssertNil([@"so/many/names/paces" objectFromEDNString], @"");
    // '/' is a special case...
    STAssertEqualObjects([@"/" objectFromEDNString], [[BMOEDNSymbol alloc] initWithNamespace:nil name:@"/"], @"");
    STAssertEqualObjects([@"foo//" objectFromEDNString], [[BMOEDNSymbol alloc] initWithNamespace:@"foo" name:@"/"], @"");
}

- (void)testDeserializeUuidTag
{
    NSUUID *uuid = [NSUUID UUID];
    STAssertEqualObjects(([[NSString stringWithFormat:@"#uuid \"%@\"",uuid.UUIDString] objectFromEDNString]), uuid, @"");
}

- (void)testDeserializeInstTag
{
    NSString *date = @"#inst \"1985-04-12T23:20:50.52Z\"";
    NSDate *forComparison = [NSDate dateWithTimeIntervalSince1970:482196050.52];
    
    STAssertEqualObjects([date objectFromEDNString], forComparison, @"");
}

#pragma mark - Writer tests

- (void)testSerializeNumerals {
    STAssertEqualObjects([@(1) ednString], @"1", @"");
    // TODO: test decimals, floats, etc. (esp for precision)
}

- (void)testSerializeString {
    STAssertEqualObjects([@"hello, world!" ednData], [@"\"hello, world!\"" dataUsingEncoding:NSUTF8StringEncoding], @"");
    STAssertEqualObjects([@"\\\"" ednString], @"\"\\\\\\\"\"", @"Backslash city.");
}

- (void)testSerializeVector {
    STAssertEqualObjects([(@[@1, @2, @"three"]) ednString], @"[ 1 2 \"three\" ]", @"");
    // TODO: whitespace options?
}

- (void)testSerializeSet {
    // Since sets come out unordered, simplest way to test is to
    // parse back in and see if it matches.
    id set = [NSSet setWithArray:(@[@1, @2, @3])];
    STAssertEqualObjects([[set ednString] objectFromEDNString], set, @"");
}

- (void)testSerializeSymbol {
    id foo = @"foo//";
    STAssertEqualObjects([[BMOEDNSymbol symbolWithNamespace:@"foo" name:@"/"] ednString], foo, @"");
    id bar = @":my/bar";
    STAssertEqualObjects([[bar objectFromEDNString] ednString], bar, @"");
}

- (void)testSerializeTaggedElements {
    // uuid
    NSUUID *uuid = [NSUUID UUID];
    STAssertEqualObjects(([uuid ednString]), ([NSString stringWithFormat:@"#uuid \"%@\"",uuid.UUIDString]), @"");
    
    // date
    NSString *date = @"#inst \"1985-04-12T23:20:50.52Z\"";
    NSDate *forComparison = [NSDate dateWithTimeIntervalSince1970:482196050.52];
    STAssertEqualObjects(([forComparison ednString]), date, @"");
    
    // arbitrary
    BMOEDNTaggedElement *taggedElement = [BMOEDNTaggedElement elementWithTag:[BMOEDNSymbol symbolWithNamespace:@"my" name:@"foo"] element:@"bar-baz"];
    NSString *taggedElementString = @"#my/foo \"bar-baz\"";
    STAssertEqualObjects([taggedElement ednString], taggedElementString, @"");
}

- (void)testSerializeMap {
    id map = @{[BMOEDNKeyword keywordWithNamespace:@"my" name:@"one"]:@1,
               [BMOEDNKeyword keywordWithNamespace:@"your" name:@"two"]:@2,
               @3:[BMOEDNSymbol symbolWithNamespace:@"surprise" name:@"three"]};
    STAssertEqualObjects([[map ednString] objectFromEDNString], map, @"Ordering is not guaranteed, so we round-trip it up.");
}

- (void)testSerializeTransmogrification {
    size_t length = 32;
    NSMutableData *data = [NSMutableData dataWithLength:length];
    //SecRandomCopyBytes(kSecRandomDefault, 32, (uint8_t *)[data bytes]);
    STAssertNil([data ednString], @"No stock transmogrifier for NSData.");
    
    NSString *dataString = [BMOEDNSerialization stringWithEDNObject:data transmogrifiers:@{(id<NSCopying>)[NSData class]:[^id(id data,NSError **err){
        return [BMOEDNTaggedElement elementWithTag:[BMOEDNSymbol symbolWithNamespace:@"edn-objc" name:@"NSData"] element:@"some data"];
    } copy]} error:NULL];
    STAssertEqualObjects(dataString, @"#edn-objc/NSData \"some data\"", @"");
}

@end
