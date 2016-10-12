//
//  DataStreamTests_mac.swift
//  DataStreamTests_mac
//
//  Created by Kaz Yoshikawa on 10/12/16.
//
//

import XCTest

class DataStreamTests_mac: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

	func testBasic1() {

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
		catch { print("\(error)") }
		let data = writeStream.data!
		XCTAssert(data.count == 1 + 2 + 4 + 1 + 2 + 4 + 4 + 8 + 1 + 1)

		let readStream = DataReadStream(data: data)
		XCTAssert(readStream.bytesAvailable == data.count)
		do {
			XCTAssert((try readStream.read() as UInt8) == 0x01)
			XCTAssert((try readStream.read() as UInt16) == 0x2345)
			XCTAssert((try readStream.read() as UInt32) == 0x6789abcd)

			XCTAssert((try readStream.read() as Int8) == -120)
			XCTAssert((try readStream.read() as Int16) == -32000)
			XCTAssert((try readStream.read() as Int32) == -100_000)

			XCTAssert((try readStream.read() as Float) == 0.5)
			XCTAssert((try readStream.read() as Double) == Double.pi)

			XCTAssert((try readStream.read() as Bool) == true)
			XCTAssert((try readStream.read() as Bool) == false)

			XCTAssert(readStream.bytesAvailable == 0)
		}
		
	}

	func testBasic2() {
		let text = "The quick brown fox jumps over the lazy dog"
	
		let writeStream = DataWriteStream()
		do {
			let data = text.data(using: .utf8)!
			try writeStream.write(UInt32(data.count))
			try writeStream.write(data)
		}
		catch { print("\(error)") }
		let data = writeStream.data!

		let readStream = DataReadStream(data: data)
		do {
			let bytes = try readStream.read() as UInt32
			let textData = try readStream.read(count: Int(bytes)) as Data
			let textValue = NSString(bytes: (textData as NSData).bytes, length: textData.count, encoding: String.Encoding.utf8.rawValue)
			XCTAssert(textValue != nil)
			XCTAssert(textValue as! String == text)
		}
		catch { print("\(error)") }
		
	}

	func testBasic3() {

		let writeStream = DataWriteStream()
		do {
			try writeStream.write(Float.infinity)
			try writeStream.write(Double.infinity)
			try writeStream.write(-Float.infinity)
			try writeStream.write(-Double.infinity)
			try writeStream.write(Float.nan)
			try writeStream.write(Double.nan)
		}
		catch { print("\(error)") }
		let data = writeStream.data!

		let readStream = DataReadStream(data: data)
		XCTAssert(readStream.bytesAvailable == data.count)
		XCTAssert((try readStream.read() as Float) == Float.infinity)
		XCTAssert((try readStream.read() as Double) == Double.infinity)
		XCTAssert((try readStream.read() as Float) == -Float.infinity)
		XCTAssert((try readStream.read() as Double) == -Double.infinity)
		XCTAssert((try readStream.read() as Float).isNaN)
		XCTAssert((try readStream.read() as Double).isNaN)
	}
    
    func testEndian1() {
		let writeStream = DataWriteStream()
		do {
			try writeStream.write(UInt8(0xef))
			try writeStream.write(UInt16(0x1234))
			try writeStream.write(UInt32(0xabcd9876))
		}
		catch {}
		let data = writeStream.data!

		let expected = Data(hexadecimalString: "ef 1234 abcd9876")
		print(expected as NSData)
		XCTAssert(data == expected)
		
    }

    func testEndian2() {
		let writeStream = DataWriteStream()
		do {
			try writeStream.write(Float(0.25))
			try writeStream.write(Double.pi)
		}
		catch {}
		let data = writeStream.data!
		let expected = Data(hexadecimalString: "3e800000 400921fb 54442d18")
		XCTAssert(data == expected)
    }
	
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
