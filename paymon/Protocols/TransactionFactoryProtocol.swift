//
//  TransactionFactoryProtocol.swift
//  paymon
//
//  Created by Jogendar Singh on 07/07/18.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import Geth
import Alamofire

protocol TransactionFactoryProtocol {
    func buildTransaction(with info: TransactionInfo, type: TransferType) throws -> GethTransaction
}


protocol TransactionServiceProtocol {
    /// Send transaction
    ///
    /// - Parameters:
    ///   - info: TransactionInfo object containing: amount, address, gas limit
    ///   - passphrase: Password to unlock wallet
    func sendTransaction(with info: TransactionInfo, passphrase: String, result: @escaping (Result<GethTransaction>) -> Void)
}
