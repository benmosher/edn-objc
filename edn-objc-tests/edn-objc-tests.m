//
//  edn-objc-tests.m
//  edn-objc-tests
//
//  Created by Ben Mosher on 8/24/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "edn-objc-tests.h"
#import "edn-objc.h"
#import "EDNLazyEnumerator.h"

// test files
#import "NSCodingFoo.h"
#import "NSCodingBar.h"

@implementation ednObjCTests

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
    STAssertEqualObjects([@"\"whee\"" ednObject], @"whee", @"");
    STAssertEqualObjects([@"\"I have a \\\"mid-quoted\\\" string in me.\\nAnd two lines.\\r\\nWindows file: \\\"C:\\\\a file.txt\\\"\"" ednObject],
                         @"I have a \"mid-quoted\" string in me.\nAnd two lines.\r\nWindows file: \"C:\\a file.txt\"", @"");
    STAssertEqualObjects([@"\"\\\\\\\"\"" ednObject], @"\\\"", @"Backslash city.");
}

- (void)testParseLiterals
{
    STAssertEquals([@"true" ednObject], (__bridge NSNumber *)kCFBooleanTrue, @"");
    STAssertEquals([@"false" ednObject], (__bridge NSNumber *)kCFBooleanFalse, @"");
    STAssertEqualObjects([@"nil" ednObject], [NSNull null], @"");
}

- (void)testParseNumerals
{
    STAssertEqualObjects([@"0" ednObject], [NSNumber numberWithInt:0], @"");
    STAssertEqualObjects([@"1.1E1" ednObject], [NSNumber numberWithDouble:11.0], @"");
    STAssertEqualObjects([@"-2" ednObject], @(-2), @"");
    STAssertEqualObjects([@"+0" ednObject], @(0), @"");
    STAssertEqualObjects([@"-0" ednObject], @(0), @"");
    STAssertEqualObjects([@"0" ednObject], @(0), @"");
    STAssertEqualObjects([@"10000N" ednObject], @(10000), @"");
    STAssertEqualObjects([@"1000.1M" ednObject], [NSDecimalNumber decimalNumberWithMantissa:10001 exponent:-1 isNegative:NO], @"");
    STAssertEqualObjects([@"1/2" ednObject], [EDNRatio ratioWithNumerator:1 denominator:2], @"");
}

- (void)testEscapes {
    STAssertEqualObjects([@"\"\n\"" ednObject], @"\n", @"Test newline");
    STAssertEqualObjects([@"\"\\n\"" ednObject], @"\n", @"Test newline");
    STAssertEqualObjects([@"\"\\\\n\"" ednObject], @"\\n", @"Test backslash, 'n'");
    STAssertEqualObjects([@"\"\\\\\n\"" ednObject], @"\\\n", @"Test backslash and newline");
}

- (void)testJavaEscapeSequences {
    // http://web.cerritos.edu/jwilson/SitePages/java_language_resources/Java_Escape_Sequences.htm
    NSArray *escapes = @[@"\\",@"\\",@"\"",@"\n",@"\t",@"\b",@"\f",@"\r"];

    for (NSString *item in escapes) {
        STAssertTrue([item length] == 1, @"has to be one char");
        NSString *parsed = [[item ednString] ednObject];
        STAssertTrue([parsed length] == 1, @"has to be one char");
        STAssertEqualObjects(parsed, item, @"has to be same value");
    }
}

- (void) testRatio {
    EDNRatio *r = [EDNRatio ratioWithNumerator:1 denominator:2];
    STAssertEquals(r.numerator, 1, @"bad numerator");
    STAssertEquals(r.denominator, 2, @"bad denominator");
    STAssertEqualObjects(r, @(0.5), @"bad value");
}

- (void) testRatioStrictMode {
    NSError *err = nil;
    STAssertNil([EDNSerialization ednObjectWithData:[@"1/2" dataUsingEncoding:NSUTF8StringEncoding] options:EDNReadingStrict error:&err], @"should not parse in strict mode");
    STAssertNotNil(err, @"");
    STAssertEquals((EDNErrorCode)err.code, EDNErrorInvalidData, @"should have return invalid data error");
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
    STAssertEqualObjects([@"[]" ednObject], @[], @"");
    STAssertEqualObjects([@"[ 1 ]" ednObject], @[@1], @"");
    id array = @[@1, @2];
    STAssertEqualObjects([@"[ 1 2 ]" ednObject], array, @"");
    array = @[@[@1, @2], @[@3], @[]];
    STAssertEqualObjects([@"[ [ 1, 2 ], [ 3 ], [] ]" ednObject], array, @"");
}

- (void)testParseLists
{
    EDNList *list = (EDNList *)[@"()" ednObject];
    STAssertTrue([list isKindOfClass:[EDNList class]], @"");
    STAssertNil([list head], @"");
    
    list = (EDNList *)[[@"[( 1 2 3 4 5 ) 1]" ednObject] objectAtIndex:0];
    STAssertTrue([list isKindOfClass:[EDNList class]], @"");
    STAssertNotNil([list head], @"");
    EDNConsCell *current = list.head;
    int i = 1;
    do {
        STAssertEqualObjects(current.first,@(i++), @"");
    } while ((current = current.rest) != nil);
    
    id<NSObject> secondList = [@"( 1 2 3 4 5 )" ednObject];
    STAssertEqualObjects(list, secondList, @"");
    STAssertEquals(list.hash, secondList.hash, @"");
}

- (void)testComments
{
    id array = @[@1, @2];
    STAssertEqualObjects([@"[ 1 ;; mid-array comment\n 2 ]" ednObject], array, @"");
    STAssertEqualObjects([@"[ 1;3\n2 ]" ednObject], array, @"");
}

- (void)testDiscards
{
    id array = @[@1, @2];
    STAssertEqualObjects([@"[ 1 #_ foo 2 ]" ednObject], array, @"");
    STAssertEqualObjects([@"[ 1 2 #_foo ]" ednObject], array, @"");
    NSError *err = nil;
    id obj = [EDNSerialization ednObjectWithData:[@"  #_fooooo  " dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&err];
    STAssertNil(obj, @"");
    // TODO: error for totally empty string?
    //STAssertNotNil(err, @"");
    //STAssertEquals(err.code, (NSInteger)EDNErrorNoData, @"");
    
    EDNList *list = (EDNList *)[@"( 1 #_foo 2 3 4 5 #_bar)" ednObject];
    STAssertTrue([list isKindOfClass:[EDNList class]], @"");
    STAssertNotNil([list head], @"");
    EDNConsCell *current = list.head;
    int i = 1;
    do {
        STAssertEqualObjects(current.first,@(i++), @"");
    } while ((current = current.rest) != nil);
}

- (void)testSets
{
    STAssertEqualObjects([@"#{}" ednObject], [NSSet setWithArray:@[]], @"");
    STAssertEqualObjects([@"#{ 1 }" ednObject], [NSSet setWithArray:@[@1]], @"");
    id set = [NSSet setWithArray:@[@1, @2]];
    STAssertEqualObjects([@"#{ 1 2 }" ednObject], set, @"");
    STAssertNil([@"#{ 1 1 2 3 5 }" ednObject], @"Repeated set members should fail.");
}

- (void)testMaps
{
    id map = @{
        @"one":@(1),
        [@"( 1 2 )" ednObject]:@"two",
        @"three":@"surprise!"};
    STAssertEqualObjects([@"{\"one\" 1 ( 1 2 ) \"two\" \"three\" \"surprise!\"}" ednObject], map, @"");
    
    STAssertEqualObjects([@"{ :one one :two + :three - :four \"four\" }" ednObject],
                         (@{
                          [@":one" ednObject]: [@"one" ednObject],
                          [@":two" ednObject]: [[EDNSymbol alloc] initWithNamespace:nil name:@"+"],
                          [@":three" ednObject]: [[EDNSymbol alloc] initWithNamespace:nil name:@"-"],
                          [@":four" ednObject]: @"four"
                          }), @"");
    STAssertNil([@"{:one 1 :one \"one\"}" ednObject],@"Repeat keys should fail.");
}

- (void)testStringCategory {
    STAssertEqualObjects([@"\"string\"" ednObject], @"string", @"");
    STAssertEqualObjects([@"[ 1 2 3 ]" ednObject], (@[(@1),(@2),(@3)]), @"");
}

- (void)testKeywords
{
    STAssertEqualObjects([@":keyword" ednObject], [[EDNKeyword alloc] initWithNamespace:nil name:@"keyword"], @"");
    STAssertEqualObjects([@":keyword" ednObject], [EDNKeyword keywordWithName:@"keyword"], @"");
    STAssertEqualObjects([@":namespaced/keyword" ednObject], [[EDNKeyword alloc] initWithNamespace:@"namespaced" name:@"keyword"], @"");
    id keyword;
    STAssertThrows(keyword = [[EDNKeyword alloc] initWithNamespace:@"something" name:nil], @"");
    STAssertNil([@":" ednObject],@"");
    STAssertNil([@":/nonamespace" ednObject], @"");
    STAssertNil([@":so/many/names/paces" ednObject], @"");
    STAssertFalse([[@":keywordsymbol" ednObject] isEqual:[@"keywordsymbol" ednObject]], @"");
    STAssertFalse([[@"symbolkeyword" ednObject] isEqual:[@":symbolkeyword" ednObject]], @"");
}

- (void)testSymbols
{
    STAssertEqualObjects([@"symbol" ednObject], [[EDNSymbol alloc] initWithNamespace:nil name:@"symbol"], @"");
    STAssertEqualObjects([@"namespaced/symbol" ednObject], [[EDNSymbol alloc] initWithNamespace:@"namespaced" name:@"symbol"], @"");
    id symbol;
    STAssertThrows(symbol = [[EDNSymbol alloc] initWithNamespace:@"something" name:nil], @"");
    STAssertNil([@"/nonamespace" ednObject], @"");
    STAssertNil([@"so/many/names/paces" ednObject], @"");
    // '/' is a special case...
    STAssertEqualObjects([@"/" ednObject], [[EDNSymbol alloc] initWithNamespace:nil name:@"/"], @"");
    STAssertEqualObjects([@"foo//" ednObject], [[EDNSymbol alloc] initWithNamespace:@"foo" name:@"/"], @"");
    
    STAssertEqualObjects([@"namespaced/<" ednObject], [[EDNSymbol alloc] initWithNamespace:@"namespaced" name:@"<"], @"");
    STAssertEqualObjects([@"namespaced/>" ednObject], [[EDNSymbol alloc] initWithNamespace:@"namespaced" name:@">"], @"");
    STAssertEqualObjects([@"html/<body>" ednObject], [[EDNSymbol alloc] initWithNamespace:@"html" name:@"<body>"], @"");
    STAssertNil([@"html/</body>" ednObject], @"");
}

- (void)testDeserializeUuidTag
{
    NSUUID *uuid = [NSUUID UUID];
    STAssertEqualObjects(([[NSString stringWithFormat:@"#uuid \"%@\"",uuid.UUIDString] ednObject]), uuid, @"");
}

- (void)testDeserializeInstTag
{
    NSString *date = @"#inst \"1985-04-12T23:20:50.52Z\"";
    NSDate *forComparison = [NSDate dateWithTimeIntervalSince1970:482196050.52];
    
    STAssertEqualObjects([date ednObject], forComparison, @"");
}

#pragma mark - Writer tests

- (void)testSerializeNumerals {
    STAssertEqualObjects([@(1) ednString], @"1", @"");
    STAssertEqualObjects([[EDNRatio ratioWithNumerator:22 denominator:7] ednString], @"22/7", @"");
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
    STAssertEqualObjects([[set ednString] ednObject], set, @"");
}

- (void)testSerializeSymbol {
    id foo = @"foo//";
    STAssertEqualObjects([[EDNSymbol symbolWithNamespace:@"foo" name:@"/"] ednString], foo, @"");
    id bar = @":my/bar";
    STAssertEqualObjects([[bar ednObject] ednString], bar, @"");
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
    EDNTaggedElement *taggedElement = [EDNTaggedElement elementWithTag:[EDNSymbol symbolWithNamespace:@"my" name:@"foo"] element:@"bar-baz"];
    NSString *taggedElementString = @"#my/foo \"bar-baz\"";
    STAssertEqualObjects([taggedElement ednString], taggedElementString, @"");
}

- (void)testSerializeMap {
    id map = @{[EDNKeyword keywordWithNamespace:@"my" name:@"one"]:@1,
               [EDNKeyword keywordWithNamespace:@"your" name:@"two"]:@2,
               @3:[EDNSymbol symbolWithNamespace:@"surprise" name:@"three"]};
    STAssertEqualObjects([[map ednString] ednObject], map, @"Ordering is not guaranteed, so we round-trip it up.");
}

- (void)testListFastEnumeration {
    EDNList *list = (EDNList *)[@"(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20)" ednObject];
    NSUInteger i = 1;
    for (NSNumber *num in list) {
        STAssertEquals(i++, [num unsignedIntegerValue], @"");
    }
}

- (void)testSerializeList {
    NSString *listString = @"( 1 2 3 4 my/symbol 6 7 8 9 #{ 10 :a :b see } 11 \"twelve\" 13 14 15 16 17 18 19 20 )";
    EDNList *list = (EDNList *)[listString ednObject];
    STAssertEqualObjects([[list ednString] ednObject], list, @"");
}

- (void)testListOperations {
    EDNList *list = [@"(4 3 2 1)" ednObject];
    EDNList *pushed = [@"(5 4 3 2 1)" ednObject];
    EDNList *popped = [@"(3 2 1)" ednObject];
    STAssertEqualObjects([list listByPushing:@5], pushed, @"");
    STAssertEqualObjects([list listByPopping], popped, @"");
}

- (void)testSerializeNull {
    STAssertEqualObjects([[NSNull null] ednString], @"nil", @"");
    id nullList = [@"( nil nil 1 nil )" ednObject];
    STAssertEqualObjects(nullList, [[nullList ednString] ednObject], @"");
}

- (void)testSerializeBooleans {
    STAssertEqualObjects([(@[(__bridge NSNumber *)kCFBooleanTrue, (__bridge NSNumber *)kCFBooleanFalse]) ednString], @"[ true false ]", @"");
    
}

// roughly 128 bits at this point.
- (void)testGiganticInteger {
    NSString *ullMax = [NSString stringWithFormat:@"%llu",ULLONG_MAX];
    NSString *number = [[ullMax stringByAppendingString:ullMax] substringToIndex:ullMax.length*2-1];
    NSLog(@"ULLONG_MAX * (2^64 + 1) / 10: %@",number);
    STAssertEqualObjects([[[number stringByAppendingString:@"N"] ednObject] ednString],number, @"");
}

- (void)testParseMetadata {
    NSString *mapWithMeta = @"^{ :my/metaKey true } { :key1 1 :key2 ^{ :my/metaKey false } 2 :listKey ( 1 2 ^{ :my/foo bar } 3 ) }";
    
    id obj = (@{ [@":key1" ednObject]: @1, [@":key2" ednObject]: @2, [@":listKey" ednObject]: [@"( 1 2 3 )" ednObject]});
    
    id parsedObj = [mapWithMeta ednObject];
    STAssertEqualObjects(parsedObj, obj, @"Meta should not be factored into equality checks.");
    
    STAssertEqualObjects([@"{ :my/metaKey true }" ednObject], [parsedObj ednMetadata], @"Find the metadata.");
    
    STAssertNil([obj ednMetadata], @"Unparsed object has no meta.");
    
    STAssertNil([@"^{ :foo \"firstMeta\" } ^{ :bar \"secondMeta\"} 1" ednObject], @"Double-meta is invalid.");
    
}


- (void)testSetMetadata {
    // ensure metadata on metadata throws an exception
    id obj2 = [NSDictionary dictionaryWithObjectsAndKeys:@1, @"one", nil];
    id meta = [NSDictionary dictionaryWithObjectsAndKeys:@2, @"two", nil];
    id metaMeta = [NSDictionary dictionaryWithObjectsAndKeys:@3, @"three", nil];
    STAssertNoThrow([obj2 setEdnMetadata:meta], @"");
    STAssertEquals(([obj2 ednMetadata]), meta, @"");
    STAssertThrows([metaMeta setEdnMetadata:obj2], @"");
    
    id literalMeta = [NSDictionary new];
    // null, true, false must not have metadata
    STAssertThrows([[NSNull null] setEdnMetadata:literalMeta], @"");
    STAssertThrows([(__bridge NSNumber *)kCFBooleanTrue setEdnMetadata:literalMeta], @"");
    STAssertThrows([(__bridge NSNumber *)kCFBooleanFalse setEdnMetadata:literalMeta], @"");
    //STAssertThrows([@"foo" setEdnMetadata:literalMeta], @"String literal may be constant and should not accept metadata (lest undefined behavior emerge)."); // yet unable to determine without hackzzz
}

- (void)testWriteMetadata {
    // write meta
    id meta = [NSDictionary new];
    NSArray *array = [NSArray arrayWithObjects:@1, @2, @3, nil];
    [array setEdnMetadata:meta];
    STAssertEqualObjects([array ednString], @"[ 1 2 3 ]", @"Empty metadata should not be serialized out.");
    [array setEdnMetadata:@{ @1: @"one" }];
    STAssertEqualObjects([array ednString], @"^{ 1 \"one\" } [ 1 2 3 ]", @"");
    id list = [@"( one two three )" ednObject];
    [list setEdnMetadata:@{ [EDNKeyword keywordWithNamespace:nil name:@"type"] : [EDNSymbol symbolWithNamespace:nil name:@"list"] }];
    array = [array arrayByAddingObject:list];
    STAssertEqualObjects([array ednString], @"[ 1 2 3 ^{ :type list } ( one two three ) ]", @"Array metadata is not preserved (array with added object is a new array).");
}

- (void)testReadMultipleRootObjects {
    NSString * obj1String = @"( 1 2 3 )";
    NSString * obj2String = @"[ 1 2 3 ]";
    NSString * objsString = [NSString stringWithFormat:@"%@ %@",obj1String, obj2String];
    id objs = [EDNSerialization ednObjectWithData:[objsString dataUsingEncoding:NSUTF8StringEncoding] options:EDNReadingMultipleObjects error:NULL];
    
    id expectedObjs = (@[[obj1String ednObject],[obj2String ednObject]]);
    
    STAssertTrue([objs conformsToProtocol:@protocol(NSFastEnumeration)], @"Multi-objects flag should return an enumerable, regardless of number of elements.");
    
    NSUInteger current = 0;
    for (id obj in objs) {
        STAssertEqualObjects(obj, expectedObjs[current++], @"");
    }
    
    STAssertEqualObjects([objsString ednObject], expectedObjs[0], @"Without multi-object flag asserted, should return first object, if valid.");
    
               
}

- (void)testWriteMultipleRootObjects {
    id objs = (@[@1, @2, @{ @"three" : @3 }]);
    STAssertEqualObjects([[[EDNRoot alloc] initWithArray:objs] ednString], @"1\n2\n{ \"three\" 3 }\n", @"");
    
    id clojureCode = @"( + 1 2 )\n( map [ x y ] ( 3 4 5 ) )\n[ a root vector is \"weird\" ]\n";
    id clojureData = [[clojureCode dataUsingEncoding:NSUTF8StringEncoding] ednObject];
    STAssertEqualObjects([clojureData ednString], clojureCode, @"");
    
    STAssertNil([(@[[[EDNRoot alloc] initWithArray:@[@1, @2]], @3]) ednString],@"Root object not at root of graph must be treated as invalid data.");
}
/*
- (void)testRootObjectEquality {
    id clojureCode = @"( + 1 2 )\n( map [ x y ] ( 3 4 5 ) )\n[ a root vector is \"weird\" ]\n";
    id clojureData = [clojureCode dataUsingEncoding:NSUTF8StringEncoding];
    id rootOne = [clojureData ednObject]; //1
    id rootTwo = [clojureData ednObject]; //1.4142
    
    STAssertFalse(rootOne == rootTwo, @"");
    STAssertEqualObjects(rootOne, rootTwo, @"Two documents derived from the same edn should be equal.");
    STAssertEquals([rootOne hash], [rootTwo hash], @"Equal objects' hashes should be equal.");
}
*/

#pragma mark - Stream reading

- (void)testReadFromStream {
    id clojureCode = @"( + 1 2 )\n( map [ x y ] ( 3 4 5 ) )\n[ a root vector is \"weird\" ]\n";
    id clojureData = [clojureCode dataUsingEncoding:NSUTF8StringEncoding];
    id clojureStream = [[NSInputStream alloc] initWithData:clojureData];
    id ednObjectStream = [clojureStream ednObject];
    NSMutableArray * collector = [NSMutableArray new];
    for (id obj in [clojureData ednObject]) {
        if (obj == nil) STFail(@"Object should not be nil.");
        [collector addObject:obj];
    }
    NSEnumerator *enumerator = [collector objectEnumerator];
    for (id obj in ednObjectStream) {
        STAssertEqualObjects(obj, [enumerator nextObject], @"");
    }
        
}

#pragma mark - EDNRoot

- (void)testNSEnumeratorBackedRootRealization {
    id objs = [@"[ 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 ]" ednObject];
    id root = [[EDNRoot alloc] initWithEnumerator:[objs objectEnumerator]];
    NSUInteger currentNumber = 1;
    for (NSNumber *num in root) {
        STAssertEquals([num unsignedIntegerValue],currentNumber++, @"");
    }
    
    // reset, attempt to re-enumerate
    currentNumber = 1;
    for (NSNumber *num in root) {
        STAssertEquals([num unsignedIntegerValue],currentNumber++, @"");
    }
    STAssertEquals(currentNumber, (NSUInteger)25, @"Root should have enumerated through all 24 objects.");
}

- (void)testRootIndexing {
    id objs = [@"[ 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 ]" ednObject];
    id root = [[EDNRoot alloc] initWithEnumerator:[objs objectEnumerator]];
    // sequentially
    for (NSUInteger i = 0; i < 10; i++) {
        STAssertEquals(i+1, [root[i] unsignedIntegerValue], @"");
    }
    
    // with realization from the end
    for (NSUInteger i = 20; i >= 10; i--) {
        STAssertEquals(i+1, [root[i] unsignedIntegerValue], @"");
    }
    
    // out of range exception
    id blah;
    STAssertThrows((blah = root[[objs count]]), @"");
    
    // same tests again, with an NSArray-backed root    
    root = [[EDNRoot alloc] initWithArray:objs];
    // sequentially
    for (NSUInteger i = 0; i < 10; i++) {
        STAssertEquals(i+1, [root[i] unsignedIntegerValue], @"");
    }
    
    // with realization from the end
    for (NSUInteger i = 20; i >= 10; i--) {
        STAssertEquals(i+1, [root[i] unsignedIntegerValue], @"");
    }
    
    // out of range exception
    STAssertThrows((blah = root[[objs count]]), @"");
}

///* TODO: fix 
- (void)testRootEnumerator {
    id objs = [@"[ 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 ]" ednObject];
    id root = [[EDNRoot alloc] initWithEnumerator:[objs objectEnumerator]];
    NSMutableSet *collector1 = [NSMutableSet new];
    NSMutableSet *collector2 = [NSMutableSet new];
    NSEnumerator *enumerator = [root objectEnumerator];
    dispatch_queue_t queue = dispatch_queue_create("RootEnumeratorTestQueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t dispatchGroup = dispatch_group_create();
    for (int i = 0; i < [objs count]/2; i++) {
        dispatch_group_async(dispatchGroup, queue, ^{
            id obj = [enumerator nextObject];
            if (obj) {
                @synchronized(collector1) {
                    [collector1 addObject:obj];
                }
            }
        });
        dispatch_group_async(dispatchGroup, queue, ^{
            id obj = [enumerator nextObject];
            if (obj) {
                @synchronized(collector2) {
                    [collector2 addObject:obj];
                }
            }
        });
    }
    STAssertEquals(0L,dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER),@"Error during group wait?");
    STAssertEquals([objs count], [collector1 count] + [collector2 count], @"Collectors should have split the objects.");
    STAssertEqualObjects([NSSet setWithArray:objs], [collector1 setByAddingObjectsFromSet:collector2], @"Collectors should contain the same set as the array did.");
}

#pragma mark - Lazy enumerator 

- (void)testLazyEnumerator {
    NSEnumerator * enumerator = [[EDNLazyEnumerator alloc] initWithBlock:^id(NSUInteger idx, id last) {
        return idx < 1000 ? @(idx) : nil;
    }];
    for (int i = 0; i < 1000; i++) {
        STAssertEqualObjects([NSNumber numberWithInt:i], [enumerator nextObject], @"");
    }
    STAssertNil([enumerator nextObject], @"");
}

- (void)testLazyErrors {
    NSError *err = nil;
    NSData *data = [@"[ 1 2 :::::}}}}}" dataUsingEncoding:NSUTF8StringEncoding];
    [EDNSerialization ednObjectWithData:data options:0 error:&err];
    STAssertTrue(err!=nil, @"Should produce an error.");
    err = nil;
    id root = [EDNSerialization ednObjectWithData:data options:EDNReadingLazyParsing|EDNReadingMultipleObjects error:&err];
    STAssertNil(err, @"Error is not immediate w/ lazy parsing.");
    NSUInteger count = 0;
    for (id obj in root) {
        STAssertTrue([obj isMemberOfClass:[NSError class]], @"Invalid data should lazily return an error.");
        STAssertTrue(count++ <= 1, @"Should only return one error.");
        
        if (count > 10) break;
    }
}

- (void)testWritingToStream {
    NSMutableString *testString = [[NSMutableString alloc] init];
    NSOutputStream *stream = [NSOutputStream outputStreamToMemory];
    NSError *err = nil;
    NSMutableArray *collector = [NSMutableArray array];
    for (int i = 0; i < 10; i++) {
        id obj = @{[NSString stringWithFormat:@"%d",i]:@(i)};
        [EDNSerialization writeEdnObject:obj toStream:stream error:&err];
        [testString appendFormat:@"{ \"%1$d\" %1$d }\n",i];
        [collector addObject:obj];
    }
    STAssertNil(err, @"");
    NSData *data = [stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    NSString *stringified = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    EDNRoot *root = [[EDNRoot alloc] initWithArray:collector];
    STAssertEqualObjects(stringified, [root ednString], @"Sanity check for comparison.");
    STAssertEqualObjects(stringified, testString, @"Multi-object stream test.");
}


#pragma mark - Characters

- (void)testParseCharacters {
    NSString *charVector = @"[ \\newline \\n \\! \\* \"fooey\" \\& \\space \\tab \\return]";
    id edn = [charVector ednObject];
    STAssertTrue(edn != nil, @"Should parse into something.");
    STAssertEqualObjects([EDNCharacter characterWithUnichar:'\n'], edn[0], @"");
    STAssertEqualObjects([EDNCharacter characterWithUnichar:'n'], edn[1], @"");
    STAssertEqualObjects([EDNCharacter characterWithUnichar:'!'], edn[2], @"");
    STAssertEqualObjects([EDNCharacter characterWithUnichar:'*'], edn[3], @"");
    STAssertEqualObjects(@"fooey", edn[4], @"");
    STAssertEqualObjects([EDNCharacter characterWithUnichar:'&'], edn[5], @"");
    STAssertEqualObjects([EDNCharacter characterWithUnichar:' '], edn[6], @"");
    STAssertEqualObjects([EDNCharacter characterWithUnichar:'\t'], edn[7], @"");
    STAssertEqualObjects([EDNCharacter characterWithUnichar:'\r'], edn[8], @"");
    
    STAssertNil([@"\\ " ednObject], @"");
}

- (void)testWriteCharacters {
    NSArray *charVector = @[[EDNCharacter characterWithUnichar:'\n'],
                            [EDNCharacter characterWithUnichar:'n'],
                            [EDNCharacter characterWithUnichar:'!'],
                            [EDNCharacter characterWithUnichar:'*'],
                            @"fooey",
                            [EDNCharacter characterWithUnichar:'&'],
                            [EDNCharacter characterWithUnichar:' '],
                            [EDNCharacter characterWithUnichar:'\t'],
                            [EDNCharacter characterWithUnichar:'\r']];
    NSString *edn = [charVector ednString];
    STAssertEqualObjects(edn, @"[ \\newline \\n \\! \\* \"fooey\" \\& \\space \\tab \\return ]", @"");
}

#pragma mark - UTF-8 (beyond ASCII)

- (void)testUTFStreamRead {
    NSString *utfString = @"πƒ©wheeyaulrd¥¨¬∂¥¨®å…œ©¬";
    NSString *ednString = [NSString stringWithFormat:@"\"%@\"",utfString];
    NSInputStream *stream = [NSInputStream inputStreamWithData:[ednString dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSError *err = nil;
    id read = [EDNSerialization ednObjectWithStream:stream options:0 error:&err];
    STAssertNil(err, @"Error should be nil.");
    
    STAssertEqualObjects(utfString, read, @"String should be read back out as it went in.");
    
    // edn UTF-8 character
    NSInputStream *charStream = [NSInputStream inputStreamWithData:[@"[ \\π ]" dataUsingEncoding:NSUTF8StringEncoding]];
    
    read = [EDNSerialization ednObjectWithStream:charStream options:0 error:&err];
    STAssertNil(err, @"Error should be nil.");
    
    STAssertEqualObjects((@[[EDNCharacter characterWithUnichar:0x03C0]]), read, @"Character array should be read back out as it went in.");
    
}

- (void)testUTFDataRead {
    NSString *utfString = @"πƒ©wheeyaulrd¥¨¬∂¥¨®å…œ©¬";
    NSString *ednString = [NSString stringWithFormat:@"\"%@\"",utfString];
    NSData *data = [ednString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *err = nil;
    id read = [EDNSerialization ednObjectWithData:data options:0 error:&err];
    STAssertNil(err, @"Error should be nil.");
    
    STAssertEqualObjects(utfString, read, @"String should be read back out as it went in.");
    
    // edn UTF-8 character
    NSData *charData = [@"[ \\π ]" dataUsingEncoding:NSUTF8StringEncoding];
    
    read = [EDNSerialization ednObjectWithData:charData options:0 error:&err];
    STAssertNil(err, @"Error should be nil.");
    
    STAssertEqualObjects((@[[EDNCharacter characterWithUnichar:0x03C0]]), read, @"Character array should be read back out as it went in.");
}

- (void)testUTFWrite {
    NSString *utfString = @"πƒ©wheeyaulrd¥¨¬∂¥¨®å…œ©¬";
    NSString *ednString = [NSString stringWithFormat:@"\"%@\"",utfString];
    STAssertEqualObjects(ednString, [[NSString alloc] initWithData:[utfString ednData] encoding:NSUTF8StringEncoding], @"String should be read back out as it went in.");
    
    // edn UTF-8 character
    ednString = @"[ \\π ]";
    
    STAssertEqualObjects([ednString dataUsingEncoding:NSUTF8StringEncoding], [(@[[EDNCharacter characterWithUnichar:0x03C0]]) ednData], @"Character array should be read back out as it went in.");
    
}

- (void)testUTF8Symbol {
    NSString *anonymous = @"(ƒ [x y] (ƒ (+ x y)))";
    // TODO: round out
    STAssertTrue([anonymous ednObject] != nil, @"");
}

- (void)testWriteNSData {
    NSData *anonData = [[NSData alloc] initWithBase64EncodedString:@"KMaSIFt4IHldICjGkiAoKyB4IHkpKSk=" options:0];
    NSString *expected = [NSString stringWithFormat:@"#edn-objc/NSData \"%@\"", [anonData base64EncodedStringWithOptions:0]];
    STAssertEqualObjects([anonData ednString], expected, @"");
}

- (void)testReadNSData {
    NSData *anonData = [[NSData alloc] initWithBase64EncodedString:@"KMaSIFt4IHldICjGkiAoKyB4IHkpKSk=" options:0];
    id roundTripped = [[anonData ednString] ednObject];
    STAssertEqualObjects(anonData, roundTripped, @"");
}

- (void)testWriteArbitraryNSCoding {
    NSCodingFoo *foo = [NSCodingFoo new];
    foo.a = 42;
    foo.b = @"life, the universe, everything";
    
    NSCodingBar *bar = [NSCodingBar new];
    bar.array = @[@3, @2, @1];
    
    foo.bar = bar;
    
    NSString *expected = @"#edn-objc/NSCodingFoo { :a 42 :b \"life, the universe, everything\" :bar #edn-objc/NSCodingBar { :array [ 3 2 1 ] :dict nil } }";
    STAssertEqualObjects([foo ednString], expected, @"");
}

- (void)testReadArbitraryNSCoding {
    NSCodingFoo *foo = [NSCodingFoo new];
    foo.a = 42;
    foo.b = @"life, the universe, everything";
    
    NSCodingBar *bar = [NSCodingBar new];
    bar.array = @[@3, @2, @1];
    
    foo.bar = bar;
    
    id roundTripped = [[foo ednString] ednObject];
    STAssertEqualObjects(foo, roundTripped, @"");
}

@end
