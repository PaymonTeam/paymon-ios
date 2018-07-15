//
//  EnumCollection.swift
//  paymon
//
//  Created by Jogendar Singh on 27/06/18.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import Foundation

import Foundation

enum TransferType {
    case `default`
    case token
}



public protocol EnumCollection: Hashable {
    static func cases() -> AnySequence<Self>
    static var allValues: [Self] { get }
}

public extension EnumCollection {

    public static func cases() -> AnySequence<Self> {
        return AnySequence { () -> AnyIterator<Self> in
            var raw = 0
            return AnyIterator {
                let current: Self = withUnsafePointer(to: &raw) { $0.withMemoryRebound(to: self, capacity: 1) { $0.pointee } }
                guard current.hashValue == raw else {
                    return nil
                }
                raw += 1
                return current
            }
        }
    }

    public static var allValues: [Self] {
        return Array(self.cases())
    }
}
