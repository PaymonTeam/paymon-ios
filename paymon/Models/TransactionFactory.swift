//
//  TransactionFactory.swift
//  paymon
//
//  Created by Jogendar Singh on 07/07/18.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import Geth

class TransactionFactory: TransactionFactoryProtocol {

    let keystore: KeystoreService
    let client: GethEthereumClient
    let context: GethContext

    init(keystore: KeystoreService, core: Ethereums) {
        self.keystore = keystore
        self.client = core.client
        self.context = core.context
    }

    func buildTransaction(with info: TransactionInfo, type: TransferType) throws -> GethTransaction {
        switch type {
        case .default:
            return try buildTransaction(with: info)
        case .token:
            return try buildTokenTransaction(with: info)
        }
    }

}

extension TransactionFactory {

    func buildTransaction(with info: TransactionInfo) throws -> GethTransaction {
        var error: NSError?
        let receiverAddress = info.contractAddress ?? info.address
        let gethAddress = GethNewAddressFromHex(receiverAddress, &error)
        var noncePointer: Int64 = 0
        let account = try keystore.getAccount(at: 0)
        try client.getNonceAt(context, account: account.getAddress(), number: -1, nonce: &noncePointer)

        let intAmount = GethNewBigInt(0)
        intAmount?.setString(info.amount.toHex(), base: 16)

        let gethGasLimit = GethNewBigInt(0)

        gethGasLimit?.setString(info.gasLimit.toHex(), base: 16)
        let gethGasPrice = GethNewBigInt(0)
        gethGasPrice?.setString(info.gasPrice.toHex(), base: 16)

        return GethNewTransaction(noncePointer, gethAddress, intAmount, (gethGasLimit?.getInt64())!, gethGasPrice, nil)
    }

    func buildTokenTransaction(with info: TransactionInfo) throws -> GethTransaction {
        let transactionTemplate = try buildTransaction(with: info)
        let transferSignature = Data(bytes: [0xa9, 0x05, 0x9c, 0xbb])
        let address = info.address.lowercased().replacingOccurrences(of: "0x", with: "")
        let hexAmount = (info.amount * 1e18).toHex().withLeadingZero(64)
        let hexData = transferSignature.toHexString() + "000000000000000000000000" + address + hexAmount
        guard let data = hexData.toHexData() else {
            throw TransactionFactoryError.badSignature
        }
        let nonce = transactionTemplate.getNonce()
        let to = transactionTemplate.getTo()
        let fakeAmount = GethBigInt(0)
        
//        let gasLimit = GethBigInt(transactionTemplate.getGas())
        let gasPrice = transactionTemplate.getGasPrice()
        return GethNewTransaction(nonce, to, fakeAmount, transactionTemplate.getGas(), gasPrice, data)
    }

}

enum TransactionFactoryError: Error {
    case badSignature
}

