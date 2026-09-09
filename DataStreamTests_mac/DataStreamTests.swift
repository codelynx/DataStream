//
//	DataStreamTests.swift
//	DataStream
//
//	Created by Kaz Yoshikawa on 10/12/16.
//
//

import XCTest
#if canImport(DataStream)
@testable import DataStream
#endif

class DataStreamTests: XCTestCase {
	
	struct RGBA8: DataRepresentable, Equatable {
		var r: UInt8
		var g: UInt8
		var b: UInt8
		var a: UInt8
	}
	
	// size is 5, stride is 8
	struct Padded: DataRepresentable, Equatable {
		var value: UInt32
		var flag: UInt8
	}
	
	// MARK: - Round trips
	
	func testPrimitivesRoundTrip() throws {
		let writeStream = DataWriteStream()
		try writeStream.write(UInt8(0x01))
		try writeStream.write(UInt16(0x2345))
		try writeStream.write(UInt32(0x6789abcd))
		try writeStream.write(UInt64(0x0123456789abcdef))
		
		try writeStream.write(Int8(-120))
		try writeStream.write(Int16(-32000))
		try writeStream.write(Int32(-100_000))
		try writeStream.write(Int64(-10_000_000_000))
		
		try writeStream.write(Float(0.5))
		try writeStream.write(Double.pi)
		
		try writeStream.write(true)
		try writeStream.write(false)
		
		let data = try XCTUnwrap(writeStream.data)
		XCTAssertEqual(data.count, 1 + 2 + 4 + 8 + 1 + 2 + 4 + 8 + 4 + 8 + 1 + 1)
		
		let readStream = DataReadStream(data: data)
		XCTAssertEqual(readStream.bytesAvailable, data.count)
		
		XCTAssertEqual(try readStream.read() as UInt8, 0x01)
		XCTAssertEqual(try readStream.read() as UInt16, 0x2345)
		XCTAssertEqual(try readStream.read() as UInt32, 0x6789abcd)
		XCTAssertEqual(try readStream.read() as UInt64, 0x0123456789abcdef)
		
		XCTAssertEqual(try readStream.read() as Int8, -120)
		XCTAssertEqual(try readStream.read() as Int16, -32000)
		XCTAssertEqual(try readStream.read() as Int32, -100_000)
		XCTAssertEqual(try readStream.read() as Int64, -10_000_000_000)
		
		XCTAssertEqual(try readStream.read() as Float, 0.5)
		XCTAssertEqual(try readStream.read() as Double, Double.pi)
		
		XCTAssertEqual(try readStream.read() as Bool, true)
		XCTAssertEqual(try readStream.read() as Bool, false)
		
		XCTAssertEqual(readStream.bytesAvailable, 0)
		XCTAssertFalse(readStream.hasBytesAvailable)
	}
	
	func testDataRoundTrip() throws {
		let text = "The quick brown fox jumps over the lazy dog"
		let textData = try XCTUnwrap(text.data(using: .utf8))
		
		let writeStream = DataWriteStream()
		try writeStream.write(UInt32(textData.count))
		try writeStream.write(textData)
		let data = try XCTUnwrap(writeStream.data)
		
		let readStream = DataReadStream(data: data)
		let count = try readStream.read() as UInt32
		let readData = try readStream.read(count: Int(count))
		XCTAssertEqual(String(data: readData, encoding: .utf8), text)
		XCTAssertFalse(readStream.hasBytesAvailable)
	}
	
	func testSpecialFloatsRoundTrip() throws {
		let writeStream = DataWriteStream()
		try writeStream.write(Float.infinity)
		try writeStream.write(Double.infinity)
		try writeStream.write(-Float.infinity)
		try writeStream.write(-Double.infinity)
		try writeStream.write(Float.nan)
		try writeStream.write(Double.nan)
		let data = try XCTUnwrap(writeStream.data)
		
		let readStream = DataReadStream(data: data)
		XCTAssertEqual(try readStream.read() as Float, Float.infinity)
		XCTAssertEqual(try readStream.read() as Double, Double.infinity)
		XCTAssertEqual(try readStream.read() as Float, -Float.infinity)
		XCTAssertEqual(try readStream.read() as Double, -Double.infinity)
		XCTAssertTrue((try readStream.read() as Float).isNaN)
		XCTAssertTrue((try readStream.read() as Double).isNaN)
	}
	
	func testDataRepresentableRoundTrip() throws {
		let rgba8 = RGBA8(r: 51, g: 65, b: 129, a: 254)
		let padded = Padded(value: 0x11223344, flag: 0x55)
		
		let writeStream = DataWriteStream()
		try writeStream.write(rgba8)
		try writeStream.write(padded)
		let data = try XCTUnwrap(writeStream.data)
		XCTAssertEqual(data.count, MemoryLayout<RGBA8>.size + MemoryLayout<Padded>.size)
		
		let readStream = DataReadStream(data: data)
		XCTAssertEqual(try readStream.read() as RGBA8, rgba8)
		XCTAssertEqual(try readStream.read() as Padded, padded)
		XCTAssertFalse(readStream.hasBytesAvailable)
	}
	
	#if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
	func testFloat16RoundTrip() throws {
		guard #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) else { return }
		let writeStream = DataWriteStream()
		try writeStream.write(Float16.pi)
		try writeStream.write(Float16(-0.25))
		let data = try XCTUnwrap(writeStream.data)
		XCTAssertEqual(data.count, MemoryLayout<Float16>.size * 2)
		
		let readStream = DataReadStream(data: data)
		XCTAssertEqual(try readStream.read() as Float16, Float16.pi)
		XCTAssertEqual(try readStream.read() as Float16, Float16(-0.25))
	}
	#endif
	
	// MARK: - Byte order
	
	func testIntegerByteOrder() throws {
		let writeStream = DataWriteStream()
		try writeStream.write(UInt8(0xef))
		try writeStream.write(UInt16(0x1234))
		try writeStream.write(UInt32(0xabcd9876))
		try writeStream.write(UInt64(0x0123456789abcdef))
		try writeStream.write(Int16(-2))
		try writeStream.write(Int64(-2))
		let data = try XCTUnwrap(writeStream.data)
		
		let expected = Data(hexadecimalString: "ef 1234 abcd9876 0123456789abcdef fffe fffffffffffffffe")
		XCTAssertEqual(data, expected)
	}
	
	func testFloatByteOrder() throws {
		let writeStream = DataWriteStream()
		try writeStream.write(Float(0.25))
		try writeStream.write(Double.pi)
		let data = try XCTUnwrap(writeStream.data)
		
		let expected = Data(hexadecimalString: "3e800000 400921fb54442d18")
		XCTAssertEqual(data, expected)
	}
	
	func testBoolEncoding() throws {
		let writeStream = DataWriteStream()
		try writeStream.write(true)
		try writeStream.write(false)
		let data = try XCTUnwrap(writeStream.data)
		XCTAssertEqual(data, Data(hexadecimalString: "ff 00"))
		
		// any non-zero byte reads as true
		let readStream = DataReadStream(data: Data(hexadecimalString: "01 00"))
		XCTAssertEqual(try readStream.read() as Bool, true)
		XCTAssertEqual(try readStream.read() as Bool, false)
	}
	
	func testDataRepresentableUsesHostByteOrder() throws {
		let padded = Padded(value: 0x11223344, flag: 0x55)
		let writeStream = DataWriteStream()
		try writeStream.write(padded)
		let data = try XCTUnwrap(writeStream.data)
		
		var copy = padded
		let hostBytes = withUnsafeBytes(of: &copy) { Data($0) }
		XCTAssertEqual(data, hostBytes)
	}
	
	// MARK: - End of stream
	
	func testEmptyStream() {
		let readStream = DataReadStream(data: Data())
		XCTAssertFalse(readStream.hasBytesAvailable)
		XCTAssertEqual(readStream.bytesAvailable, 0)
		XCTAssertThrowsError(try readStream.read() as UInt8) { error in
			XCTAssertTrue(error is DataStreamError)
		}
	}
	
	func testHasBytesAvailable() throws {
		let readStream = DataReadStream(data: Data(hexadecimalString: "01 02"))
		XCTAssertTrue(readStream.hasBytesAvailable)
		XCTAssertEqual(readStream.bytesAvailable, 2)
		_ = try readStream.read() as UInt8
		XCTAssertTrue(readStream.hasBytesAvailable)
		XCTAssertEqual(readStream.bytesAvailable, 1)
		_ = try readStream.read() as UInt8
		XCTAssertFalse(readStream.hasBytesAvailable)
		XCTAssertEqual(readStream.bytesAvailable, 0)
	}
	
	func testReadPastEndThrows() {
		let readStream = DataReadStream(data: Data(hexadecimalString: "01"))
		XCTAssertThrowsError(try readStream.read() as UInt16)
	}
	
	func testReadCountPastEndThrows() {
		let readStream = DataReadStream(data: Data(hexadecimalString: "01 02 03"))
		XCTAssertThrowsError(try readStream.read(count: 4))
	}
	
	func testReadDataRepresentablePastEndThrows() {
		let readStream = DataReadStream(data: Data(hexadecimalString: "01 02 03"))
		XCTAssertThrowsError(try readStream.read() as RGBA8)
	}
	
	// MARK: - CoreGraphics
	
	#if canImport(CoreGraphics)
	func testCG() throws {
		let p1 = CGPoint(x: 200, y: 300)
		let s1 = CGSize(width: 1024, height: 768)
		let t1 = CGAffineTransform.identity.scaledBy(x: 2, y: 2).translatedBy(x: 800, y: 400).rotated(by: CGFloat.pi)
		
		let writeStream = DataWriteStream()
		try writeStream.write(CGFloat(1.5))
		try writeStream.write(p1)
		try writeStream.write(s1)
		try writeStream.write(t1)
		let data = try XCTUnwrap(writeStream.data)
		XCTAssertEqual(data.count, 8 * (1 + 2 + 2 + 6))
		
		let readStream = DataReadStream(data: data)
		XCTAssertEqual(try readStream.read() as CGFloat, 1.5)
		XCTAssertEqual(try readStream.read() as CGPoint, p1)
		XCTAssertEqual(try readStream.read() as CGSize, s1)
		let t2 = try readStream.read() as CGAffineTransform
		XCTAssertEqual(t2, t1)
		
		let basePoint = CGPoint(x: 300, y: 200)
		XCTAssertEqual(basePoint.applying(t2), basePoint.applying(t1))
		XCTAssertFalse(readStream.hasBytesAvailable)
	}
	#endif
	
}
