//
//  DecimalExtension.swift
//  paymon
//
//  Created by Jogendar Singh on 01/07/18.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import Foundation

extension Decimal {

    init(_ string: String) {
        if let _ = Decimal(string: string) {
            self.init(string: string)!
            return
        }

        self.init(string: "0")!
    }

    var string: String {
        return String(describing: self)
    }

    var double: Double {
        return NSDecimalNumber(decimal:self).doubleValue
    }

    func abbrevation() -> String {
        let numFormatter = NumberFormatter()

        typealias Abbrevation = (threshold: Decimal, divisor: Decimal, suffix: String)
        let abbreviations:[Abbrevation] = [(0, 1, ""),
                                           (1000.0, 1000.0, "K"),
                                           (100_000.0, 1_000_000.0, "M"),
                                           (100_000_000.0, 1_000_000_000.0, "B")]
        // you can add more !

        let abbreviation: Abbrevation = {
            var prevAbbreviation = abbreviations[0]
            for tmpAbbreviation in abbreviations {
                if self < tmpAbbreviation.threshold {
                    break
                }
                prevAbbreviation = tmpAbbreviation
            }
            return prevAbbreviation
        } ()

        let value = self / abbreviation.divisor
        numFormatter.positiveSuffix = abbreviation.suffix
        numFormatter.negativeSuffix = abbreviation.suffix
        numFormatter.allowsFloats = true
        numFormatter.minimumIntegerDigits = 1
        numFormatter.minimumFractionDigits = 0
        numFormatter.maximumFractionDigits = 1

        return numFormatter.string(for: value) ?? self.string
    }

}

extension Double {

    func amount(for iso: String) -> String {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = .current
        currencyFormatter.currencyCode = iso
        return currencyFormatter.string(from: Decimal(floatLiteral: self) as NSDecimalNumber)!
    }

}
extension Decimal {

    func fromWei() -> Decimal {
        return self / 1e18
    }

    func toWei() -> Decimal {
        return self * 1e18
    }

    func localToEther(rate: Double) -> Decimal {
        return self / Decimal(rate)
    }

    func etherToLocal(rate: Double) -> Decimal {
        return self * Decimal(rate)
    }

    func weiToGwei() -> Decimal {
        return self / 1000000000
    }

    func toHex() -> String {
        return representationOf(base: 16)
    }

    func amount(for iso: String) -> String {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = .current
        currencyFormatter.currencyCode = iso
        return currencyFormatter.string(from: self as NSDecimalNumber)!
    }

    init(hexString: String) {
        self.init(hexString, base: 16)
    }

}

// MARK: - Privates

extension Decimal {

    private func rounded(mode: NSDecimalNumber.RoundingMode) -> Decimal {
        var this = self
        var result = Decimal()
        NSDecimalRound(&result, &this, 0, mode)

        return result
    }

    private func integerDivisionBy(_ operand: Decimal) -> Decimal{
        let result = (self / operand)
        return result.rounded(mode: result < 0 ? .up : .down)
    }

    private func truncatingRemainder(dividingBy operand: Decimal) -> Decimal {
        return self - self.integerDivisionBy(operand) * operand
    }

    init(_ string: String, base: Int) {
        var decimal: Decimal = 0

        let digits = string.characters
            .map { String($0) }
            .map { Int($0, radix: base)! }

        for digit in digits {
            decimal *= Decimal(base)
            decimal += Decimal(digit)
        }

        self.init(string: decimal.description)!
    }

    func representationOf(base: Decimal) -> String {
        var buffer: [Int] = []
        var n = self

        while n > 0 {
            buffer.append((n.truncatingRemainder(dividingBy: base) as NSDecimalNumber).intValue)
            n = n.integerDivisionBy(base)
        }

        return buffer
            .reversed()
            .map { String($0, radix: (base as NSDecimalNumber).intValue ) }
            .joined()
    }
}

