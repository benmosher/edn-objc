//
//  edn-objc-tests.m
//  edn-objc-tests
//
//  Created by Ben Mosher on 8/24/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "edn-objc-tests.h"
#import "edn-objc.h"
#import "BMOLazyEnumerator.h"

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
    BMOEDNList *list = (BMOEDNList *)[@"()" ednObject];
    STAssertTrue([list isKindOfClass:[BMOEDNList class]], @"");
    STAssertNil([list head], @"");
    
    list = (BMOEDNList *)[[@"[( 1 2 3 4 5 ) 1]" ednObject] objectAtIndex:0];
    STAssertTrue([list isKindOfClass:[BMOEDNList class]], @"");
    STAssertNotNil([list head], @"");
    BMOEDNConsCell *current = list.head;
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
    id obj = [BMOEDNSerialization ednObjectWithData:[@"  #_fooooo  " dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&err];
    STAssertNil(obj, @"");
    // TODO: error for totally empty string?
    //STAssertNotNil(err, @"");
    //STAssertEquals(err.code, (NSInteger)BMOEDNErrorNoData, @"");
    
    BMOEDNList *list = (BMOEDNList *)[@"( 1 #_foo 2 3 4 5 #_bar)" ednObject];
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
                          [@":two" ednObject]: [[BMOEDNSymbol alloc] initWithNamespace:nil name:@"+"],
                          [@":three" ednObject]: [[BMOEDNSymbol alloc] initWithNamespace:nil name:@"-"],
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
    STAssertEqualObjects([@":keyword" ednObject], [[BMOEDNKeyword alloc] initWithNamespace:nil name:@"keyword"], @"");
    STAssertEqualObjects([@":namespaced/keyword" ednObject], [[BMOEDNKeyword alloc] initWithNamespace:@"namespaced" name:@"keyword"], @"");
    id keyword;
    STAssertThrows(keyword = [[BMOEDNKeyword alloc] initWithNamespace:@"something" name:nil], @"");
    STAssertNil([@":" ednObject],@"");
    STAssertNil([@":/nonamespace" ednObject], @"");
    STAssertNil([@":so/many/names/paces" ednObject], @"");
    STAssertFalse([[@":keywordsymbol" ednObject] isEqual:[@"keywordsymbol" ednObject]], @"");
    STAssertFalse([[@"symbolkeyword" ednObject] isEqual:[@":symbolkeyword" ednObject]], @"");
}

- (void)testSymbols
{
    STAssertEqualObjects([@"symbol" ednObject], [[BMOEDNSymbol alloc] initWithNamespace:nil name:@"symbol"], @"");
    STAssertEqualObjects([@"namespaced/symbol" ednObject], [[BMOEDNSymbol alloc] initWithNamespace:@"namespaced" name:@"symbol"], @"");
    id symbol;
    STAssertThrows(symbol = [[BMOEDNSymbol alloc] initWithNamespace:@"something" name:nil], @"");
    STAssertNil([@"/nonamespace" ednObject], @"");
    STAssertNil([@"so/many/names/paces" ednObject], @"");
    // '/' is a special case...
    STAssertEqualObjects([@"/" ednObject], [[BMOEDNSymbol alloc] initWithNamespace:nil name:@"/"], @"");
    STAssertEqualObjects([@"foo//" ednObject], [[BMOEDNSymbol alloc] initWithNamespace:@"foo" name:@"/"], @"");
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
    STAssertEqualObjects([[BMOEDNSymbol symbolWithNamespace:@"foo" name:@"/"] ednString], foo, @"");
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
    BMOEDNTaggedElement *taggedElement = [BMOEDNTaggedElement elementWithTag:[BMOEDNSymbol symbolWithNamespace:@"my" name:@"foo"] element:@"bar-baz"];
    NSString *taggedElementString = @"#my/foo \"bar-baz\"";
    STAssertEqualObjects([taggedElement ednString], taggedElementString, @"");
}

- (void)testSerializeMap {
    id map = @{[BMOEDNKeyword keywordWithNamespace:@"my" name:@"one"]:@1,
               [BMOEDNKeyword keywordWithNamespace:@"your" name:@"two"]:@2,
               @3:[BMOEDNSymbol symbolWithNamespace:@"surprise" name:@"three"]};
    STAssertEqualObjects([[map ednString] ednObject], map, @"Ordering is not guaranteed, so we round-trip it up.");
}

- (void)testSerializeTransmogrification {
    size_t length = 32;
    NSMutableData *data = [NSMutableData dataWithLength:length];
    //SecRandomCopyBytes(kSecRandomDefault, 32, (uint8_t *)[data bytes]);
    STAssertNil([data ednString], @"No stock transmogrifier for NSData.");
    
    NSString *dataString = [BMOEDNSerialization stringWithEdnObject:data transmogrifiers:@{(id<NSCopying>)[NSData class]:[^id(id data,NSError **err){
        return [BMOEDNTaggedElement elementWithTag:[BMOEDNSymbol symbolWithNamespace:@"edn-objc" name:@"NSData"] element:@"some data"];
    } copy]} error:NULL];
    STAssertEqualObjects(dataString, @"#edn-objc/NSData \"some data\"", @"");
}

- (void)testListFastEnumeration {
    BMOEDNList *list = (BMOEDNList *)[@"(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20)" ednObject];
    NSUInteger i = 1;
    for (NSNumber *num in list) {
        STAssertEquals(i++, [num unsignedIntegerValue], @"");
    }
}

- (void)testSerializeList {
    NSString *listString = @"( 1 2 3 4 my/symbol 6 7 8 9 #{ 10 :a :b see } 11 \"twelve\" 13 14 15 16 17 18 19 20 )";
    BMOEDNList *list = (BMOEDNList *)[listString ednObject];
    STAssertEqualObjects([[list ednString] ednObject], list, @"");
}

- (void)testListOperations {
    BMOEDNList *list = [@"(4 3 2 1)" ednObject];
    BMOEDNList *pushed = [@"(5 4 3 2 1)" ednObject];
    BMOEDNList *popped = [@"(3 2 1)" ednObject];
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
    [list setEdnMetadata:@{ [BMOEDNKeyword keywordWithNamespace:nil name:@"type"] : [BMOEDNSymbol symbolWithNamespace:nil name:@"list"] }];
    array = [array arrayByAddingObject:list];
    STAssertEqualObjects([array ednString], @"[ 1 2 3 ^{ :type list } ( one two three ) ]", @"Array metadata is not preserved (array with added object is a new array).");
}

- (void)testReadMultipleRootObjects {
    NSString * obj1String = @"( 1 2 3 )";
    NSString * obj2String = @"[ 1 2 3 ]";
    NSString * objsString = [NSString stringWithFormat:@"%@ %@",obj1String, obj2String];
    id objs = [BMOEDNSerialization ednObjectWithData:[objsString dataUsingEncoding:NSUTF8StringEncoding] options:BMOEDNReadingMultipleObjects error:NULL];
    
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
    STAssertEqualObjects([[[BMOEDNRoot alloc] initWithArray:objs] ednString], @"1\n2\n{ \"three\" 3 }\n", @"");
    
    id clojureCode = @"( + 1 2 )\n( map [ x y ] ( 3 4 5 ) )\n[ a root vector is \"weird\" ]\n";
    id clojureData = [[clojureCode dataUsingEncoding:NSUTF8StringEncoding] ednObject];
    STAssertEqualObjects([clojureData ednString], clojureCode, @"");
    
    STAssertNil([(@[[[BMOEDNRoot alloc] initWithArray:@[@1, @2]], @3]) ednString],@"Root object not at root of graph must be treated as invalid data.");
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

#pragma mark - BMOEDNRoot

- (void)testNSEnumeratorBackedRootRealization {
    id objs = [@"[ 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 ]" ednObject];
    id root = [[BMOEDNRoot alloc] initWithEnumerator:[objs objectEnumerator]];
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
    id root = [[BMOEDNRoot alloc] initWithEnumerator:[objs objectEnumerator]];
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
    root = [[BMOEDNRoot alloc] initWithArray:objs];
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

- (void)testRootEnumerator {
    id objs = [@"[ 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 ]" ednObject];
    id root = [[BMOEDNRoot alloc] initWithEnumerator:[objs objectEnumerator]];
    NSMutableSet *collector1 = [NSMutableSet new];
    NSMutableSet *collector2 = [NSMutableSet new];
    NSEnumerator *enumerator = [root objectEnumerator];
    dispatch_queue_t queue = dispatch_queue_create("RootEnumeratorTestQueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t dispatchGroup = dispatch_group_create();
    for (int i = 0; i < [objs count]/2; i++) {
        dispatch_group_async(dispatchGroup, queue, ^{
            [collector1 addObject:[enumerator nextObject]];
        });
        dispatch_group_async(dispatchGroup, queue, ^{
            [collector2 addObject:[enumerator nextObject]];
        });
    }
    STAssertEquals(0L,dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER),@"Error during group wait?");
    STAssertEquals([objs count], [collector1 count] + [collector2 count], @"Collectors should have split the objects.");
    STAssertEqualObjects([NSSet setWithArray:objs], [collector1 setByAddingObjectsFromSet:collector2], @"Collectors should contain the same set as the array did.");
}

#pragma mark - Lazy enumerator 

- (void)testLazyEnumerator {
    NSEnumerator * enumerator = [[BMOLazyEnumerator alloc] initWithBlock:^id(NSUInteger idx, id last) {
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
    [BMOEDNSerialization ednObjectWithData:data options:0 error:&err];
    STAssertTrue(err!=nil, @"Should produce an error.");
    err = nil;
    id root = [BMOEDNSerialization ednObjectWithData:data options:BMOEDNReadingLazyParsing|BMOEDNReadingMultipleObjects error:&err];
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
        [BMOEDNSerialization writeEdnObject:obj toStream:stream error:&err];
        [testString appendFormat:@"{ \"%1$d\" %1$d }\n",i];
        [collector addObject:obj];
    }
    STAssertNil(err, @"");
    NSData *data = [stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    NSString *stringified = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    BMOEDNRoot *root = [[BMOEDNRoot alloc] initWithArray:collector];
    STAssertEqualObjects(stringified, [root ednString], @"Sanity check for comparison.");
    STAssertEqualObjects(stringified, testString, @"Multi-object stream test.");
}

@end
