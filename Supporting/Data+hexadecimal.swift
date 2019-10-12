//
//  NSData+Z.swift
//  ZKit
//
//  Created by Kaz Yoshikawa on 12/11/15.
//  Copyright © 2015 Electricwoods LLC. All rights reserved.
//

import Foundation


//
//	extension NSData
//

extension Data {
	
	init(hexadecimalString: String) {
		
		let table: [Character : UInt8] = [
			"0": 0x0, "1": 0x1, "2": 0x2, "3": 0x3,  "4": 0x4, "5": 0x5, "6": 0x6, "7": 0x7,
			"8": 0x8, "9": 0x9, "a": 0xa, "b": 0xb,  "c": 0xc, "d": 0xd, "e": 0xe, "f": 0xf,
			"A": 0xa, "B": 0xb, "C": 0xc, "D": 0xd,  "E": 0xe, "F": 0xf
		]
		
		var data = Data()
		var count = 0
		var byte: UInt8 = 0
		for ch in hexadecimalString {
			if let value = table[ch] {
				if count % 2 == 0 {
					byte = value
				}
				else {
					byte = byte * 0x10 + value
					data.append(&byte, count: 1)
				}
				count += 1
			}
			else if ch==" " || ch=="\t" { // just ignore
			}
		}
		self = data
	}
	
}
