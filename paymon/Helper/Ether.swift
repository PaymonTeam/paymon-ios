//
//  Ether.swift
//  paymon
//
//  Created by Jogendar Singh on 01/07/18.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import UIKit

struct Ether {

    let raw: Decimal
    let value: Double

    init(_ value: Decimal) {
        self.raw = value
        self.value = value.double
    }

    init(weiValue: Decimal) {
        self.raw = weiValue / 1e18
        self.value = weiValue.double / 1e18
    }

    init(_ double: Double) {
        self.raw = Decimal(double)
        self.value = double
    }

    init(_ string: String) {
        let number = Decimal(string)
        self.init(number)
    }

    init(weiString: String) {
        let number = Decimal(weiString)
        self.init(weiValue: number)
    }

}

extension Ether: Currency {

    var name: String {
        return "Ethereum"
    }

    var iso: String {
        return "ETH"
    }

    var symbol: String {
        return "Ξ"
    }

}

protocol Currency {
    var raw: Decimal { get }
    var value: Double { get }
    var name: String { get }
    var iso: String { get }
    var symbol: String { get }
}

// MARK: - Common helpers

extension Currency {
    var fullName: String {
        return "\(name) (\(iso))"
    }

    var fullNameWithSymbol: String {
        return "\(symbol)\t\(fullName)"
    }

    var amount: String {
        let valueString = NSDecimalNumber(string: "\(value)").stringValue
        return "\(valueString) \(symbol)"
    }

    func amount(in iso: String, rate: Double) -> String {
        let total = value * rate
        return total.amount(for: iso)
    }

}

