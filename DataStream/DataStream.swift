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


@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension Float16: DataRepresentable {
}


//
//	DataStreamError
//

enum DataStreamError: Error {
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
	
	public init(data: Data) {
		self.inputStream = InputStream(data: data)
		self.inputStream.open()
		self.bytes = data.count
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
	
	public func readBytes<T>() throws -> T {
		let valueSize = MemoryLayout<T>.size
		var buffer = [UInt8](repeating: 0, count: valueSize)
		let value: T = try buffer.withUnsafeMutableBytes { mutableRawBufferPointer throws -> T in
			let bufferPointer: UnsafeMutablePointer<UInt8> = mutableRawBufferPointer.baseAddress!.assumingMemoryBound(to: UInt8.self)
			if self.inputStream.read(bufferPointer, maxLength: valueSize) != valueSize {
				throw DataStreamError.readError
			}
			return bufferPointer.withMemoryRebound(to: T.self, capacity: 1) {
				return $0.pointee
			}
		}
		self.offset += valueSize
		return value
	}
	
	public func read() throws -> Int8 {
		return try self.readBytes() as Int8
	}
	public func read() throws -> UInt8 {
		return try self.readBytes() as UInt8
	}
	
	public func read() throws -> Int16 {
		let value = try self.readBytes() as UInt16
		return Int16(bitPattern: CFSwapInt16BigToHost(value))
	}
	public func read() throws -> UInt16 {
		let value = try self.readBytes() as UInt16
		return CFSwapInt16BigToHost(value)
	}
	
	public func read() throws -> Int32 {
		let value = try self.readBytes() as UInt32
		return Int32(bitPattern: CFSwapInt32BigToHost(value))
	}
	public func read() throws -> UInt32 {
		let value = try self.readBytes() as UInt32
		return CFSwapInt32BigToHost(value)
	}
	
	public func read() throws -> Int64 {
		let value = try self.readBytes() as UInt64
		return Int64(bitPattern: CFSwapInt64BigToHost(value))
	}
	public func read() throws -> UInt64 {
		let value = try self.readBytes() as UInt64
		return CFSwapInt64BigToHost(value)
	}
	
	public func read() throws -> Float {
		let value = try self.readBytes() as CFSwappedFloat32
		return CFConvertFloatSwappedToHost(value)
	}
	public func read() throws -> Float64 {
		let value = try self.readBytes() as CFSwappedFloat64
		return CFConvertFloat64SwappedToHost(value)
	}
	@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
	public func read() throws -> Float16 {
		let binary = try self.read(count: MemoryLayout<Float16>.size)
		return try binary.instanciate(as: Float16.self)
	}
	public func read<T: DataRepresentable>() throws -> T {
		let binary = try self.read(count: MemoryLayout<T>.size)
		return try binary.instanciate(as: T.self)
	}
	
	public func read(count: Int) throws -> Data {
		var buffer = [UInt8](repeating: 0, count: count)
		if self.inputStream.read(&buffer, maxLength: count) != count {
			throw DataStreamError.readError
		}
		offset += count
		return NSData(bytes: buffer, length: buffer.count) as Data
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
	
	public init() {
		self.outputStream = OutputStream.toMemory()
		self.outputStream.open()
	}
	
	deinit {
		self.outputStream.close()
	}
	
	public var data: Data? {
		return self.outputStream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data
	}
	
	public func writeBytes<T>(_ value: T) throws {
		let valueSize = MemoryLayout<T>.size
		var value = value
		let result = withUnsafeBytes(of: &value) { rawBufferPointer in
			let pointer: UnsafePointer<UInt8> = rawBufferPointer.baseAddress!.assumingMemoryBound(to: UInt8.self)
			return (outputStream.write(pointer, maxLength: valueSize) == valueSize)
		}
		if !result { throw DataStreamError.writeError }
	}
	
	public func write(_ value: Int8) throws {
		try writeBytes(value)
	}
	public func write(_ value: UInt8) throws {
		try writeBytes(value)
	}
	
	public func write(_ value: Int16) throws {
		try writeBytes(CFSwapInt16HostToBig(UInt16(bitPattern: value)))
	}
	public func write(_ value: UInt16) throws {
		try writeBytes(CFSwapInt16HostToBig(value))
	}
	
	public func write(_ value: Int32) throws {
		try writeBytes(CFSwapInt32HostToBig(UInt32(bitPattern: value)))
	}
	public func write(_ value: UInt32) throws {
		try writeBytes(CFSwapInt32HostToBig(value))
	}
	
	public func write(_ value: Int64) throws {
		try writeBytes(CFSwapInt64HostToBig(UInt64(bitPattern: value)))
	}
	public func write(_ value: UInt64) throws {
		try writeBytes(CFSwapInt64HostToBig(value))
	}
	
	public func write(_ value: Float32) throws {
		try writeBytes(CFConvertFloatHostToSwapped(value))
	}
	public func write(_ value: Float64) throws {
		try writeBytes(CFConvertFloat64HostToSwapped(value))
	}
	@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
	public func write(_ value: Float16) throws {
		let binary = value.dataRepresentation
		try self.write(binary)
	}
	public func write<T: DataRepresentable>(_ value: T) throws {
		let binary = value.dataRepresentation
		try self.write(binary)
	}
	public func write(_ data: Data) throws {
		let bytesWritten = data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> Int in
			return outputStream.write(Array(pointer.bindMemory(to: UInt8.self)), maxLength: data.count)
		}
		if bytesWritten != data.count { throw DataStreamError.writeError }
	}
	
	public func write(_ value: Bool) throws {
		try writeBytes(UInt8(value ? 0xff : 0x00))
	}
}

