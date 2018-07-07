//
//  Transaction.swift
//  paymon
//
//  Created by Jogendar Singh on 08/07/18.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import Foundation
import Geth
import ObjectMapper

struct Transaction {
    var txHash: String!
    var to: String!
    var from: String!
    var amount: Currency!
    var timestamp: Date!
    var isIncoming: Bool!
    var isPending: Bool!
    var isError: Bool!
    var isTokenTransfer: Bool!

    static func mapFromGethTransaction(_ object: GethTransaction, time: TimeInterval) -> Transaction {
        var transaction = Transaction()
        transaction.txHash = object.getHash().getHex()
        transaction.to = object.getTo().getHex()
        transaction.from = ""
        transaction.amount = Ether(weiString: object.getValue().string()!)
        transaction.timestamp = Date(timeIntervalSince1970: time)
        transaction.isPending = false
        transaction.isError = false
        transaction.isTokenTransfer = false
        return transaction
    }

}

// MARK: - ImmutableMappable

extension Transaction: ImmutableMappable {

    init(map: Map) throws {
        txHash = try map.value("hash")
        to = try map.value("to")
        from = try map.value("from")
        let amountString: String = try map.value("value")
        amount = Ether(weiString: amountString)
        timestamp = try map.value("timeStamp", using: DateTransform())
        let isErrorString: String = try map.value("isError")
        isError = Bool(isErrorString)
        isPending = false
        isTokenTransfer = false
    }

}
