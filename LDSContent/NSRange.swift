//
//  NSRange.swift
//  LDSContent
//
//  Created by Hilton Campbell on 2/15/16.
//  Copyright © 2016 Hilton Campbell. All rights reserved.
//

import Foundation

extension NSRange: Equatable {}

public func == (lhs: NSRange, rhs: NSRange) -> Bool {
    return NSEqualRanges(lhs, rhs)
}
