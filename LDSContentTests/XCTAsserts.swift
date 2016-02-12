//
//  XCTAsserts.swift
//  LDSContent
//
//  Created by Hilton Campbell on 2/11/16.
//  Copyright © 2016 Hilton Campbell. All rights reserved.
//

import XCTest

func XCTAssertNoThrow<T>(@autoclosure expression: () throws -> T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    do {
        try expression()
    } catch let error {
        XCTFail("Caught error: \(error) - \(message)", file: file, line: line)
    }
}

func XCTAssertNoThrowEqual<T : Equatable>(@autoclosure expression1: () throws -> T, @autoclosure _ expression2: () throws -> T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    do {
        let result1 = try expression1()
        let result2 = try expression2()
        XCTAssertEqual(result1, result2, message, file: file, line: line)
    } catch let error {
        XCTFail("Caught error: \(error) - \(message)", file: file, line: line)
    }
}
