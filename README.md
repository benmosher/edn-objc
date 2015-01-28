edn-objc
========

[![build](https://travis-ci.org/benmosher/edn-objc.svg?branch=master)](https://travis-ci.org/benmosher/edn-objc)

A work-in-progress implementation of [edn-format](https://github.com/edn-format/edn) for Objective-C/Foundation platforms (e.g. iOS and OSX).

Current design goals are completeness and spec adherence. Any valid edn data deserialized into Cocoa/EDN objects should be serialized back to the same edn UTF-8 data (barring whitespace, both in strings and amidst the edn data). This includes the 'root'; the top-level objects that are not within any root container.

Tagged elements (such as the built-in `uuid` and `inst`) may be converted to concrete Cocoa objects (again, `NSUUID` and `NSDate`) via implementation of the `EDNRepresentation` protocol, and registering with `EDNRegistry` during `+load`. See the `NSUUID+EDN` and `NSDate+EDN` implementations for detail.

'Unknown' tagged elements will be converted to/from `EDNTaggedElement` during de/serialization. 

Objects that implement keyed `NSCoding` will be written out as a map tagged with `#edn-objc/[the class name]`. Objects serialized this way may also be reconstituted at read time. Secure decoding is not yet supported.

Numbers are read exclusively into `NSDecimalNumber` and seem to afford around 128 bits of mantissa. So far, no support for arbitrary precision integers. Ratios are also supported by default, but disabled in 'strict' mode.

Lazy deserialization from `NSInputStream` is supported, and lazy parsing can be consumed by multiple threads using the root object's `-objectEnumerator`. Lazy parsing is limited to top-level objects at this time; a given object will be fully parsed into memory immediately.

Note: very little testing has occurred so far; the goal was to get a roughed-in version of reading and writing behind a decent interface out into the world. YMMV on OSX and iOS < 6.1. If you see an issue, I'd love to see a test that exposes it. Notably, using `NSUUID` for `#uuid` creates a dependency on iOS 6+.

##Entry points

The primary entry point is `EDNSerialization`, which exposes an `NSJSONSerialization`-style API for parsing strings, data, or streams, as well as writing object graphs back to the same.

There are a few categories defined; `NSData`, `NSInputStream`, and `NSString` each have an `-ednObject` category method that will attempt to parse the instance (returning `nil` on failure). `NSObject` defines `-ednString` and `-ednData` methods to attempt to write out the object as the root. 

The `NSObject` category also defines a `metadata` property, allowing the association of a metadata dictionary. This will be set at read time and written out at serialization time.

##Object Mapping

`edn` ⇌ `Cocoa`

#####'Pure' Cocoa mappings

`string` ⇌ `NSString` (surprise!)

`vector` ⇌ `NSArray`

`map` ⇌ `NSDictionary`

`integer`, `floating point` ⇌ `NSDecimalNumber`

`set` ⇌ `NSSet`

`nil` ⇌ `NSNull`

* `nil` is also written out for nil/NULL pointers, but currently read in as `NSNull`. 

`booleans` ⇌ `CFBoolean` (bridged with `NSNumber`)

* Specifically: `kCFBooleanTrue` and `kCFBooleanFalse`.

`#inst` ⇌ `NSDate`

`#uuid` ⇌ `NSUUID`

bonus! `metadata` ⇌ `NSDictionary`

#####Custom object mappings

root (top-level)  `EDNRoot`

`list` ⇌ `EDNList`

`character` ⇌ `EDNCharacter`

`symbol` ⇌ `EDNSymbol`

`keyword` ⇌ `EDNKeyword`

arbitrary tags ⇌ `EDNTaggedElement`

`ratio` ⇌ `EDNRatio`


###License

This project is licensed under the Eclipse Public License, v1.
