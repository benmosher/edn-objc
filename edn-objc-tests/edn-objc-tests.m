//
//  edn-objc-tests.m
//  edn-objc-tests
//
//  Created by Ben Mosher on 8/24/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "edn-objc-tests.h"
#import "edn-objc.h"


@implementation EDNObjCTests

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
    STAssertEqualObjects([@"\"\\\\\\\"\"" EDNObject], @"\\\"", @"Backslash city.");
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
    STAssertEqualObjects([@"-2" EDNObject], @(-2), @"");
    STAssertEqualObjects([@"+0" EDNObject], @(0), @"");
    STAssertEqualObjects([@"-0" EDNObject], @(0), @"");
    STAssertEqualObjects([@"0" EDNObject], @(0), @"");
    STAssertEqualObjects([@"10000N" EDNObject], @(10000), @"");
    STAssertEqualObjects([@"1000.1M" EDNObject], [NSDecimalNumber decimalNumberWithMantissa:10001 exponent:-1 isNegative:NO], @"");
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
    STAssertNil([@"#{ 1 1 2 3 5 }" EDNObject], @"Repeated set members should fail.");
}

- (void)testMaps
{
    id map = @{
        @"one":@(1),
        [BMOEDNSerialization EDNObjectWithData:[@"( 1 2 )" dataUsingEncoding:NSUTF8StringEncoding]
                                         error:NULL]:@"two",
        @"three":@"surprise!"};
    STAssertEqualObjects([BMOEDNSerialization EDNObjectWithData:[@"{\"one\" 1 ( 1 2 ) \"two\" \"three\" \"surprise!\"}" dataUsingEncoding:NSUTF8StringEncoding] error:NULL], map, @"");
    
    STAssertEqualObjects([@"{ :one one :two + :three - :four \"four\" }" EDNObject],
                         (@{
                          [@":one" EDNObject]: [@"one" EDNObject],
                          [@":two" EDNObject]: [[BMOEDNSymbol alloc] initWithNamespace:nil name:@"+"],
                          [@":three" EDNObject]: [[BMOEDNSymbol alloc] initWithNamespace:nil name:@"-"],
                          [@":four" EDNObject]: @"four"
                          }), @"");
    STAssertNil([@"{:one 1 :one \"one\"}" EDNObject],@"Repeat keys should fail.");
}

- (void)testStringCategory {
    STAssertEqualObjects([@"\"string\"" EDNObject], @"string", @"");
    STAssertEqualObjects([@"[ 1 2 3 ]" EDNObject], (@[(@1),(@2),(@3)]), @"");
}

- (void)testKeywords
{
    STAssertEqualObjects([@":keyword" EDNObject], [[BMOEDNKeyword alloc] initWithNamespace:nil name:@"keyword"], @"");
    STAssertEqualObjects([@":namespaced/keyword" EDNObject], [[BMOEDNKeyword alloc] initWithNamespace:@"namespaced" name:@"keyword"], @"");
    id keyword;
    STAssertThrows(keyword = [[BMOEDNKeyword alloc] initWithNamespace:@"something" name:nil], @"");
    STAssertNil([@":" EDNObject],@"");
    STAssertNil([@":/nonamespace" EDNObject], @"");
    STAssertNil([@":so/many/names/paces" EDNObject], @"");
    STAssertFalse([[@":keywordsymbol" EDNObject] isEqual:[@"keywordsymbol" EDNObject]], @"");
    STAssertFalse([[@"symbolkeyword" EDNObject] isEqual:[@":symbolkeyword" EDNObject]], @"");
}

- (void)testSymbols
{
    STAssertEqualObjects([@"symbol" EDNObject], [[BMOEDNSymbol alloc] initWithNamespace:nil name:@"symbol"], @"");
    STAssertEqualObjects([@"namespaced/symbol" EDNObject], [[BMOEDNSymbol alloc] initWithNamespace:@"namespaced" name:@"symbol"], @"");
    id symbol;
    STAssertThrows(symbol = [[BMOEDNSymbol alloc] initWithNamespace:@"something" name:nil], @"");
    STAssertNil([@"/nonamespace" EDNObject], @"");
    STAssertNil([@"so/many/names/paces" EDNObject], @"");
    // '/' is a special case...
    STAssertEqualObjects([@"/" EDNObject], [[BMOEDNSymbol alloc] initWithNamespace:nil name:@"/"], @"");
    STAssertEqualObjects([@"foo//" EDNObject], [[BMOEDNSymbol alloc] initWithNamespace:@"foo" name:@"/"], @"");
}

- (void)testDeserializeUuidTag
{
    NSUUID *uuid = [NSUUID UUID];
    STAssertEqualObjects(([[NSString stringWithFormat:@"#uuid \"%@\"",uuid.UUIDString] EDNObject]), uuid, @"");
}

- (void)testDeserializeInstTag
{
    NSString *date = @"#inst \"1985-04-12T23:20:50.52Z\"";
    NSDate *forComparison = [NSDate dateWithTimeIntervalSince1970:482196050.52];
    
    STAssertEqualObjects([date EDNObject], forComparison, @"");
}

#pragma mark - Writer tests

- (void)testSerializeNumerals {
    STAssertEqualObjects([@(1) EDNString], @"1", @"");
    // TODO: test decimals, floats, etc. (esp for precision)
}

- (void)testSerializeString {
    STAssertEqualObjects([@"hello, world!" EDNData], [@"\"hello, world!\"" dataUsingEncoding:NSUTF8StringEncoding], @"");
    STAssertEqualObjects([@"\\\"" EDNString], @"\"\\\\\\\"\"", @"Backslash city.");
}

- (void)testSerializeVector {
    STAssertEqualObjects([(@[@1, @2, @"three"]) EDNString], @"[ 1 2 \"three\" ]", @"");
    // TODO: whitespace options?
}

- (void)testSerializeSet {
    // Since sets come out unordered, simplest way to test is to
    // parse back in and see if it matches.
    id set = [NSSet setWithArray:(@[@1, @2, @3])];
    STAssertEqualObjects([[set EDNString] EDNObject], set, @"");
}

- (void)testSerializeSymbol {
    id foo = @"foo//";
    STAssertEqualObjects([[BMOEDNSymbol symbolWithNamespace:@"foo" name:@"/"] EDNString], foo, @"");
    id bar = @":my/bar";
    STAssertEqualObjects([[bar EDNObject] EDNString], bar, @"");
}

- (void)testSerializeTaggedElements {
    // uuid
    NSUUID *uuid = [NSUUID UUID];
    STAssertEqualObjects(([uuid EDNString]), ([NSString stringWithFormat:@"#uuid \"%@\"",uuid.UUIDString]), @"");
    
    // date
    NSString *date = @"#inst \"1985-04-12T23:20:50.52Z\"";
    NSDate *forComparison = [NSDate dateWithTimeIntervalSince1970:482196050.52];
    STAssertEqualObjects(([forComparison EDNString]), date, @"");
    
    // arbitrary
    BMOEDNTaggedElement *taggedElement = [BMOEDNTaggedElement elementWithTag:[BMOEDNSymbol symbolWithNamespace:@"my" name:@"foo"] element:@"bar-baz"];
    NSString *taggedElementString = @"#my/foo \"bar-baz\"";
    STAssertEqualObjects([taggedElement EDNString], taggedElementString, @"");
}

- (void)testSerializeMap {
    id map = @{[BMOEDNKeyword keywordWithNamespace:@"my" name:@"one"]:@1,
               [BMOEDNKeyword keywordWithNamespace:@"your" name:@"two"]:@2,
               @3:[BMOEDNSymbol symbolWithNamespace:@"surprise" name:@"three"]};
    STAssertEqualObjects([[map EDNString] EDNObject], map, @"Ordering is not guaranteed, so we round-trip it up.");
}

- (void)testSerializeTransmogrification {
    size_t length = 32;
    NSMutableData *data = [NSMutableData dataWithLength:length];
    //SecRandomCopyBytes(kSecRandomDefault, 32, (uint8_t *)[data bytes]);
    STAssertNil([data EDNString], @"No stock transmogrifier for NSData.");
    
    NSString *dataString = [BMOEDNSerialization stringWithEDNObject:data transmogrifiers:@{(id<NSCopying>)[NSData class]:[^id(id data,NSError **err){
        return [BMOEDNTaggedElement elementWithTag:[BMOEDNSymbol symbolWithNamespace:@"edn-objc" name:@"NSData"] element:@"some data"];
    } copy]} error:NULL];
    STAssertEqualObjects(dataString, @"#edn-objc/NSData \"some data\"", @"");
}

- (void)testListFastEnumeration {
    BMOEDNList *list = (BMOEDNList *)[@"(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20)" EDNObject];
    NSUInteger i = 1;
    for (NSNumber *num in list) {
        STAssertEquals(i++, [num unsignedIntegerValue], @"");
    }
}

- (void)testSerializeList {
    NSString *listString = @"( 1 2 3 4 my/symbol 6 7 8 9 #{ 10 :a :b see } 11 \"twelve\" 13 14 15 16 17 18 19 20 )";
    BMOEDNList *list = (BMOEDNList *)[listString EDNObject];
    STAssertEqualObjects([[list EDNString] EDNObject], list, @"");
}

- (void)testListOperations {
    BMOEDNList *list = [@"(4 3 2 1)" EDNObject];
    BMOEDNList *pushed = [@"(5 4 3 2 1)" EDNObject];
    BMOEDNList *popped = [@"(3 2 1)" EDNObject];
    STAssertEqualObjects([list listByPushing:@5], pushed, @"");
    STAssertEqualObjects([list listByPopping], popped, @"");
}

- (void)testSerializeNull {
    STAssertEqualObjects([[NSNull null] EDNString], @"nil", @"");
    id nullList = [@"( nil nil 1 nil )" EDNObject];
    STAssertEqualObjects(nullList, [[nullList EDNString] EDNObject], @"");
}

- (void)testSerializeBooleans {
    STAssertEqualObjects([(@[(__bridge NSNumber *)kCFBooleanTrue, (__bridge NSNumber *)kCFBooleanFalse]) EDNString], @"[ true false ]", @"");
    
}

// roughly 128 bits at this point.
- (void)testGiganticInteger {
    NSString *ullMax = [NSString stringWithFormat:@"%llu",ULLONG_MAX];
    NSString *number = [[ullMax stringByAppendingString:ullMax] substringToIndex:ullMax.length*2-1];
    NSLog(@"ULLONG_MAX * (2^64 + 1) / 10: %@",number);
    STAssertEqualObjects([[[number stringByAppendingString:@"N"] EDNObject] EDNString],number, @"");
}

- (void)testParseMetadata {
    NSString *mapWithMeta = @"^{ :my/metaKey true } { :key1 1 :key2 ^{ :my/metaKey false } 2 :listKey ( 1 2 ^{ :my/foo bar } 3 ) }";
    
    id obj = (@{ [@":key1" EDNObject]: @1, [@":key2" EDNObject]: @2, [@":listKey" EDNObject]: [@"( 1 2 3 )" EDNObject]});
    
    id parsedObj = [mapWithMeta EDNObject];
    STAssertEqualObjects(parsedObj, obj, @"Meta should not be factored into equality checks.");
    
    STAssertEqualObjects([@"{ :my/metaKey true }" EDNObject], [parsedObj EDNMetadata], @"Find the metadata.");
    
    STAssertNil([obj EDNMetadata], @"Unparsed object has no meta.");
    
    STAssertNil([@"^{ :foo \"firstMeta\" } ^{ :bar \"secondMeta\"} nil" EDNObject], @"Double-meta is invalid.");
}

@end
