# DataStream

![swift](https://img.shields.io/badge/Swift-5.7+-orange.svg)
![platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS-blue.svg)
![license](https://img.shields.io/badge/License-MIT-yellow.svg)

DataStream is a small Swift utility for writing and reading primitives such as `Int32` or `Float` to and from binary `Data`. There is no header or schema in the output, so the types and their order must match exactly between writing and reading.

All integers and floating point values are stored in big-endian byte order regardless of the host, so data written on one platform can be read on another, or by other tools that understand the layout below.

## Requirements

- Swift 5.7 or later
- macOS 10.15, iOS 13, tvOS 13, or watchOS 6 or later

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
	.package(url: "https://github.com/codelynx/DataStream.git", branch: "master"),
],
targets: [
	.target(name: "MyTarget", dependencies: ["DataStream"]),
]
```

Or in Xcode, choose File > Add Package Dependencies… and enter the repository URL.

## Byte Format

| Type | Bytes | Encoding |
|---|---|---|
| `Int8`, `UInt8` | 1 | as is |
| `Int16`, `UInt16` | 2 | big-endian |
| `Int32`, `UInt32` | 4 | big-endian |
| `Int64`, `UInt64` | 8 | big-endian |
| `Float` | 4 | IEEE 754 single, big-endian |
| `Double` | 8 | IEEE 754 double, big-endian |
| `Bool` | 1 | `0xff` for true, `0x00` for false; any non-zero byte reads as true |
| `Data` | count | as is, no length prefix |
| `CGFloat` | 8 | always written as `Double` |
| `CGPoint` | 16 | `x`, `y` as `Double` |
| `CGSize` | 16 | `width`, `height` as `Double` |
| `CGAffineTransform` | 48 | `a`, `b`, `c`, `d`, `tx`, `ty` as `Double` |
| `Float16` | 2 | raw memory, host byte order |
| `DataRepresentable` | `MemoryLayout<T>.size` | raw memory, host byte order |

Signed integers use two's complement. `Float16` is available where the platform provides it, which excludes Intel Macs. The CoreGraphics types are available where CoreGraphics can be imported.

## Writing

```swift
import DataStream

let writeStream = DataWriteStream()
do {
	try writeStream.write(UInt8(0x01))
	try writeStream.write(UInt16(0x2345))
	try writeStream.write(UInt32(0x6789abcd))

	try writeStream.write(Int8(-120))
	try writeStream.write(Int16(-32000))
	try writeStream.write(Int32(-100_000))

	try writeStream.write(Float(0.5))
	try writeStream.write(Double.pi)

	try writeStream.write(true)
	try writeStream.write(false)
}
catch { ... }

if let data = writeStream.data {
	...
}
```

## Reading

```swift
let readStream = DataReadStream(data: data)
do {
	let a = try readStream.read() as UInt8  // 0x01
	let b = try readStream.read() as UInt16 // 0x2345
	let c = try readStream.read() as UInt32 // 0x6789abcd

	let d = try readStream.read() as Int8  // -120
	let e = try readStream.read() as Int16 // -32000
	let f = try readStream.read() as Int32 // -100_000

	let g = try readStream.read() as Float  // 0.5
	let h = try readStream.read() as Double // Double.pi

	let i = try readStream.read() as Bool // true
	let j = try readStream.read() as Bool // false
}
catch { ... }
```

## Errors

Reading past the end of the stream throws `DataStreamError.readError`. A failed write throws `DataStreamError.writeError`.

```swift
do {
	let value = try readStream.read() as UInt32
}
catch DataStreamError.readError {
	// not enough bytes left
}
```

To avoid the error, check before reading. `hasBytesAvailable` is true while unread bytes remain, and `bytesAvailable` returns how many.

```swift
while readStream.hasBytesAvailable {
	// read more
}
```

## Sub-Data

You may write a chunk of `Data` into a stream. The stream does not record its length, so write a length prefix yourself.

```swift
let subdata: Data = ...
try writeStream.write(UInt32(subdata.count))
try writeStream.write(subdata)
```

Then read it back the same way.

```swift
let length = try readStream.read() as UInt32
let subdata = try readStream.read(count: Int(length))
```

## CoreGraphics Types

`CGFloat`, `CGPoint`, `CGSize`, and `CGAffineTransform` are written as `Double` components, so the format is the same on every platform.

```swift
try writeStream.write(CGPoint(x: 200, y: 300))
try writeStream.write(CGSize(width: 1024, height: 768))
try writeStream.write(CGAffineTransform(rotationAngle: .pi))

let point = try readStream.read() as CGPoint
let size = try readStream.read() as CGSize
let transform = try readStream.read() as CGAffineTransform
```

## Custom Data

Fixed-size structs can be written and read as a single value by conforming them to `DataRepresentable`. The default implementation copies the raw memory of the value, so it is only suitable for plain structs made of fixed-size fields.

```swift
import CoreLocation

struct RGBA8: DataRepresentable {
	var r: UInt8
	var g: UInt8
	var b: UInt8
	var a: UInt8
}

extension CLLocationCoordinate2D: DataRepresentable {
}
```

Write them like any other value.

```swift
let rgba8: RGBA8 = ...
let location: CLLocationCoordinate2D = ...
try writeStream.write(rgba8)
try writeStream.write(location)
```

And read them back.

```swift
let rgba8 = try readStream.read() as RGBA8
let location = try readStream.read() as CLLocationCoordinate2D
```

Types containing strings, classes, or other variable-length data must not conform to `DataRepresentable`. Their raw memory holds pointers, not the content.

```swift
struct Foo: DataRepresentable {
	var name: String    // not suitable: String is not fixed-size
	var number: NSNumber // not suitable: classes are references
}
```

Two caveats apply to `DataRepresentable` values:

- They are written in host byte order, unlike the primitive overloads. Data containing them is only portable between hosts of the same endianness.
- Any padding bytes inside the struct are written as well, and their contents are unspecified. Two equal values can therefore produce different bytes, so do not compare or hash the output. Ordering fields from largest to smallest avoids padding in most cases.

## License

MIT License. See [LICENSE](LICENSE).
