edn-objc
========

A work-in-progress implementation of [edn-format](https://github.com/edn-format) for Objective-C/Foundation platforms (e.g. iOS and OSX).

Current design goals are completeness and spec adherence. Any valid edn data deserialized into Cocoa/BMOEDN objects should be serialized back to the same edn UTF-8 data (barring whitespace, both in strings and amidst the edn data). This includes the 'root'; the top-level primitives that are not within any root container.

Tagged elements (such as the built-in `uuid` and `inst`) may be converted to concrete Cocoa objects (again, `NSUUID` and `NSDate`) via implementation of the `BMOEDNRepresentation` protocol, and registering with `BMOEDNRegistry` during `+load`. See the `NSUUID+BMOEDN` and `NSDate+BMOEDN` implementations for detail.

'Unknown' tagged elements will be converted to/from `BMOEDNTaggedElement` during de/serialization. A dictionary of `BMOEDNTransmogrifier` blocks may be provided to further customize tagged element conversion, without protocol implementation (or to use >1 tag + format per class). 

Numbers are read exclusively into `NSDecimalNumber` and seem to afford around 128 bits of mantissa. So far, no support for arbitrary precision integers.

Lazy deserialization from `NSInputStream` is supported, and lazy parsing can be consumed by multiple threads using the root object's `-objectEnumerator`. Lazy parsing is limited to top-level objects at this time; a given object will be fully parsed into memory immediately.

Note: very little testing has occurred so far; the goal was to get a roughed-in version of reading and writing behind a decent interface out into the world. YMMV on OSX and iOS < 6.1. If you see an issue, I'd love to see a test that exposes it. Notably, using `NSUUID` for `#uuid` creates a dependency on iOS 6+.

##Entry points

The primary entry point is `BMOEDNSerialization`, which exposes an `NSJSONSerialization`-style API for parsing strings, data, or streams, as well as writing object graphs back to the same.

There are a few categories defined; `NSData`, `NSInputStream`, and `NSString` each have an `-ednObject` category method that will attempt to parse the instance (returning `nil` on failure). `NSObject` defines `-ednString` and `-ednData` methods to attempt to write out the object as the root. 

The `NSObject` category also defines a `metadata` property, allowing the association of a metadata dictionary. This will be set at read time and written out at serialization time.

##Object Mapping

`edn`: `Cocoa`

#####'Pure' Cocoa mappings

`string`: `NSString` (surprise!)

`vector`: `NSArray`

`map`: `NSDictionary`

`integer`, `floating point`: `NSDecimalNumber`

`set`: `NSSet`

`nil`: `NSNull`

`booleans`: `CFBoolean`[^1] (bridged with `NSNumber`)

[^1]: Specifically: `kCFBooleanTrue` and `kCFBooleanFalse`.

`#inst`: `NSDate`

`#uuid`: `NSUUID`

bonus! `metadata`: `NSDictionary`

#####Custom object mappings

root (top-level): `BMOEDNRoot`

`list`: `BMOEDNList`

`character`: `BMOEDNCharacter`

`symbol`: `BMOEDNSymbol`

`keyword`: `BMOEDNKeyword`

arbitrary tags: `BMOEDNTaggedElement`


###License

This project is licensed under the BSD 2-Clause License.
