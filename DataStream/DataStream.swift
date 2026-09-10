//
//	DataStream.swift
//	ZKit
//
//	The MIT License (MIT)
//
//	Copyright (c) 2016 Electricwoods LLC, Kaz Yoshikawa.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy 
//	of this software and associated documentation files (the "Software"), to deal 
//	in the Software without restriction, including without limitation the rights 
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
//	copies of the Software, and to permit persons to whom the Software is 
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in 
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.
//
//

import Foundation


//
//	ByteOrder
//

public enum ByteOrder {
	case bigEndian
	case littleEndian
}


//
//	DataStreamError
//

public enum DataStreamError: Error {
	case readError
	case writeError
}


//
//	DataReadStream
//

public class DataReadStream {
	
	private var inputStream: InputStream
	private let bytes: Int
	private var offset: Int = 0
	public let byteOrder: ByteOrder
	
	public init(data: Data, byteOrder: ByteOrder = .bigEndian) {
		self.inputStream = InputStream(data: data)
		self.inputStream.open()
		self.bytes = data.count
		self.byteOrder = byteOrder
	}
	
	deinit {
		self.inputStream.close()
	}
	
	public var hasBytesAvailable: Bool {
		return self.inputStream.hasBytesAvailable
	}
	
	public var bytesAvailable: Int {
		return self.bytes - self.offset
	}
	
	private func readBytes<T>() throws -> T {
		let valueSize = MemoryLayout<T>.size
		guard valueSize <= self.bytesAvailable else { throw DataStreamError.readError }
		var buffer = [UInt8](repeating: 0, count: valueSize)
		if self.inputStream.read(&buffer, maxLength: valueSize) != valueSize {
			throw DataStreamError.readError
		}
		self.offset += valueSize
		return buffer.withUnsafeBytes { $0.loadUnaligned(as: T.self) }
	}
	
	private func readInteger<T: FixedWidthInteger>() throws -> T {
		let raw = try self.readBytes() as T
		switch self.byteOrder {
		case .bigEndian: return T(bigEndian: raw)
		case .littleEndian: return T(littleEndian: raw)
		}
	}
	
	public func read() throws -> Int8 {
		return try self.readBytes() as Int8
	}
	public func read() throws -> UInt8 {
		return try self.readBytes() as UInt8
	}
	
	public func read() throws -> Int16 {
		return try self.readInteger()
	}
	public func read() throws -> UInt16 {
		return try self.readInteger()
	}
	
	public func read() throws -> Int32 {
		return try self.readInteger()
	}
	public func read() throws -> UInt32 {
		return try self.readInteger()
	}
	
	public func read() throws -> Int64 {
		return try self.readInteger()
	}
	public func read() throws -> UInt64 {
		return try self.readInteger()
	}
	
	public func read() throws -> Float {
		return Float(bitPattern: try self.readInteger())
	}
	public func read() throws -> Double {
		return Double(bitPattern: try self.readInteger())
	}
	#if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
	@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
	public func read() throws -> Float16 {
		return Float16(bitPattern: try self.readInteger())
	}
	#endif
	
	public func read(count: Int) throws -> Data {
		guard count >= 0, count <= self.bytesAvailable else { throw DataStreamError.readError }
		var buffer = [UInt8](repeating: 0, count: count)
		if self.inputStream.read(&buffer, maxLength: count) != count {
			throw DataStreamError.readError
		}
		self.offset += count
		return Data(buffer)
	}
	
	public func read() throws -> Bool {
		let byte = try self.read() as UInt8
		return byte != 0
	}
	
}

//
//	DataWriteStream
//


public class DataWriteStream {
	
	private var outputStream: OutputStream
	public let byteOrder: ByteOrder
	
	public init(byteOrder: ByteOrder = .bigEndian) {
		self.outputStream = OutputStream.toMemory()
		self.outputStream.open()
		self.byteOrder = byteOrder
	}
	
	deinit {
		self.outputStream.close()
	}
	
	public var data: Data? {
		return self.outputStream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data
	}
	
	private func writeBytes<T>(_ value: T) throws {
		let valueSize = MemoryLayout<T>.size
		var value = value
		let result = withUnsafeBytes(of: &value) { rawBufferPointer in
			let pointer: UnsafePointer<UInt8> = rawBufferPointer.baseAddress!.assumingMemoryBound(to: UInt8.self)
			return (outputStream.write(pointer, maxLength: valueSize) == valueSize)
		}
		if !result { throw DataStreamError.writeError }
	}
	
	private func writeInteger<T: FixedWidthInteger>(_ value: T) throws {
		switch self.byteOrder {
		case .bigEndian: try self.writeBytes(value.bigEndian)
		case .littleEndian: try self.writeBytes(value.littleEndian)
		}
	}
	
	public func write(_ value: Int8) throws {
		try writeBytes(value)
	}
	public func write(_ value: UInt8) throws {
		try writeBytes(value)
	}
	
	public func write(_ value: Int16) throws {
		try writeInteger(value)
	}
	public func write(_ value: UInt16) throws {
		try writeInteger(value)
	}
	
	public func write(_ value: Int32) throws {
		try writeInteger(value)
	}
	public func write(_ value: UInt32) throws {
		try writeInteger(value)
	}
	
	public func write(_ value: Int64) throws {
		try writeInteger(value)
	}
	public func write(_ value: UInt64) throws {
		try writeInteger(value)
	}
	
	public func write(_ value: Float) throws {
		try writeInteger(value.bitPattern)
	}
	public func write(_ value: Double) throws {
		try writeInteger(value.bitPattern)
	}
	#if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
	@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
	public func write(_ value: Float16) throws {
		try writeInteger(value.bitPattern)
	}
	#endif
	public func write(_ data: Data) throws {
		if data.isEmpty { return }
		let bytesWritten = data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> Int in
			return outputStream.write(pointer.baseAddress!.assumingMemoryBound(to: UInt8.self), maxLength: data.count)
		}
		if bytesWritten != data.count { throw DataStreamError.writeError }
	}
	
	public func write(_ value: Bool) throws {
		try writeBytes(UInt8(value ? 0xff : 0x00))
	}
}
