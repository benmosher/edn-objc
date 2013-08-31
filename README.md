edn-objc
========

A work-in-progress implementation of [edn-format](https://github.com/edn-format) for Objective-C/Foundation platforms (e.g. iOS and OSX).

Current design goals are completeness and spec adherence.

Tagged elements (such as the built-in `uuid` and `inst`) may be converted to concrete Cocoa objects (again, `NSUUID` and `NSDate`) via implementation of the `BMOEDNRepresentation` protocol, and registering with `BMOEDNRegistry` during `+load`. See the `NSUUID+BMOEDN` and `NSDate+BMOEDN` implementations for detail.

'Unknown' tagged elements will be converted to/from `BMOEDNTaggedElement` during de/serialization. A dictionary of `BMOEDNTransmogrifier` blocks may be provided to further customize tagged element conversion, without protocol implementation (or to use >1 tag + format per class). 

Numbers are read exclusively into `NSDecimalNumber` and seem to afford around 128 bits of mantissa. So far, no support for arbitrary precision integers.

Note: very little testing has occurred so far; the goal was to get a roughed-in version of reading and writing behind a decent interface out into the world. YMMV on OSX and iOS < 6.1.

This project is licensed under the BSD 2-Clause License.
