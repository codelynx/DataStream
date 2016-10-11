# DataStream

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


### License

MIT License

