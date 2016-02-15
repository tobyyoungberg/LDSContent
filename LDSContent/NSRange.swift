//
//  NSRange.swift
//  LDSContent
//
//  Created by Hilton Campbell on 2/15/16.
//  Copyright © 2016 Hilton Campbell. All rights reserved.
//

import Foundation

func == (lhs: NSRange, rhs: NSRange) -> Bool {
    return NSEqualRanges(lhs, rhs)
}
