# DataStream

![xcode](https://img.shields.io/badge/Xcode-14-blue.svg)
![swift](https://img.shields.io/badge/Swift-5.7-orange.svg)
![license](https://img.shields.io/badge/License-MIT-yellow.svg)


DataStream is a Swift utility code to save or load primitives such as Int or Float.  You will have to know the format of binary image.  And reading and writing types and order must be matched, or you may not able to save and load your binary formatted data.

DataStream convert integer and floating point numbers to big endian based, so should be able to exchange binary data between Mac (Intel - little endian) and iOS (ARM - big endian).

### Writing Binary Formatted Data

```.swift
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

### Reading Binary Formatted Data

```.swift
let readStream = DataReadStream(data: data)
do {
	let a = try readStream.read() as UInt8 // 0x01
	let b = try readStream.read() as UInt16 // 0x2345
	let c = try readStream.read() as UInt32 // 0x6789abcd

	let d = try readStream.read() as Int8 // -120
	let e = try readStream.read() as Int16 //  -32000
	let f = try readStream.read() as Int32 // -100_000

	let g = try readStream.read() as Float // 0.5
	let h = try readStream.read() as Double // Double.pi

	let h = try readStream.read() as Bool // true
	let i = try readStream.read() as Bool // false
}
catch { ... }
```


### Writing and reading binary data

You may write sub-binary data into a stream.  But be aware that when you are reading this sub-binary data you can't tell the length of sub data, so you may like to write a hint about number of sub data as follows.


```.swift
	let subdata = ...
	try writeStream.write(data.count)
	try writeStream.write(data)
```

Then you may read sub-binary data as follows.

```.swift
	let length = try readStream.read() as Int
	let subdata = try readStream.read(count: length) as Data
```

### Checking if ReadStream is at end of the stream

You may also like to know if the read stream is at end or not.


```.swift
	while readStream.hasBytesAvailable {
		// read more
	}
```

### Custom Data

When you would like to write and to read fixed sized structured data, you may conform those structs to `DataRepresentable`, or to provide extension to conform `DataRepresentable` like following code.  
Although 

```.swift
	struct RGB8: DataRepresentable {
		var r: UInt8
		var g: UInt8
		var b: UInt8
		var a: UInt8
	}
	
	extension CLLocationCoordinate2D: DataRepresentable {
	}
```

You may write them with the following code.

```.swift
	let rgb8: RGB8 = ...
	let location: CLLocationCoordinate2D = ...
	try writeStream.write(rgb8)
	try writeStream.write(location)
```

Then you may read with the following code.

```.swift
	let rgba8 = try readStream.read() as RGBA8
	let location2d = try readStream.read(count: length) as CLLocationCoordinate2D
```

Be aware that struct contains string, classes or other non-fixed data format.

```.swift
	struct Foo: DataRepresentable {
		var name: String  // `String` is not appropriate for `DataRepresentable`
		var number: NSNumber  // `class` is not appropriate for `DataRepresentable`
	}
```


### License

MIT License

