//
//	DataStream+CG.swift
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

import Foundation
import CoreGraphics


extension DataWriteStream {
	
	func write(_ value: CGFloat) throws {
		try self.write(Float64(value))
	}
	
	func write(_ value: CGPoint) throws {
		try self.write(Float64(value.x))
		try self.write(Float64(value.y))
	}
	
	func write(_ value: CGSize) throws {
		try self.write(Float64(value.width))
		try self.write(Float64(value.height))
	}
	
	func write(_ value: CGAffineTransform) throws {
		try self.write(Float64(value.a))
		try self.write(Float64(value.b))
		try self.write(Float64(value.c))
		try self.write(Float64(value.d))
		try self.write(Float64(value.tx))
		try self.write(Float64(value.ty))
	}
	
}

extension DataReadStream {
	
	func read() throws -> CGFloat {
		return CGFloat(try self.read() as Double)
	}
	
	func read() throws -> CGPoint {
		let x = try self.read() as Float64
		let y = try self.read() as Float64
		return CGPoint(x: x, y: y)
	}
	
	func read() throws -> CGSize {
		let width = try self.read() as Float64
		let height = try self.read() as Float64
		return CGSize(width: width, height: height)
	}
	
	func read() throws -> CGAffineTransform {
		var transform = CGAffineTransform.identity
		transform.a = try self.read() as CGFloat
		transform.b = try self.read() as CGFloat
		transform.c = try self.read() as CGFloat
		transform.d = try self.read() as CGFloat
		transform.tx = try self.read() as CGFloat
		transform.ty = try self.read() as CGFloat
		return transform
	}
	
}
