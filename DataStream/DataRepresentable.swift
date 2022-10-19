//
//	DataRepresentable.swift
//	ZKit
//
//	Created by Kaz Yoshikawa on 10/18/22.
//

import Foundation

private enum DataRepresentableError: Error {
	case dataTooSmall
}

public protocol DataRepresentable {
	var dataRepresentation: Data { get }
}

public extension DataRepresentable {
	var dataRepresentation: Data {
		var value: Self = self
		return Data(bytes: &value, count: MemoryLayout<Self>.size)
	}
}

public extension Data {
	func instanciate<T: DataRepresentable>(as type: T.Type) throws -> T {
		guard self.count >= MemoryLayout<T>.size else { throw DataRepresentableError.dataTooSmall }
		let unsafeRawPointer = (self as NSData).bytes
		let unsafePointer = UnsafePointer<T>(OpaquePointer(unsafeRawPointer))
		return unsafePointer.pointee
	}
}
