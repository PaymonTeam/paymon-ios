//
//  TransactionService.swift
//  paymon
//
//  Created by Jogendar Singh on 08/07/18.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import Geth
import Alamofire

class TransactionService: TransactionServiceProtocol {

    private let context: GethContext
    private let client: GethEthereumClient
    private let keystore: KeystoreService
    private let chain: Chain
    private let factory: TransactionFactoryProtocol
    private let transferType: TransferType
    var vc: UIViewController?
    init(core: Ethereums, keystore: KeystoreService, transferType: TransferType, viewC: UIViewController) {
        self.context = core.context
        self.client = core.client
        self.chain = core.chain
        self.keystore = keystore
        self.transferType = transferType
        self.vc = viewC 
        let factory = TransactionFactory(keystore: keystore, core: core)
        self.factory = factory
    }

    func sendTransaction(with info: TransactionInfo, passphrase: String, result: @escaping (Result<GethTransaction>) -> Void) {
        Ethereums.syncQueue.async {
            do {
                let account = try self.keystore.getAccount(at: 0)
                let transaction = try self.factory.buildTransaction(with: info, type: self.transferType)
                let signedTransaction = try self.keystore.signTransaction(transaction, account: account, passphrase: passphrase, chainId: self.chain.chainId)
                try self.sendTransaction(signedTransaction)
                DispatchQueue.main.async {
                    result(.success(signedTransaction))
                }
            } catch {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Alert", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                    let okBtn = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
                    alert.addAction(okBtn)
                    self.vc?.present(alert, animated: true, completion: nil)
                    result(.failure(error))
                }
            }
        }
    }

    private func sendTransaction(_ signedTransaction: GethTransaction) throws {
        try client.sendTransaction(context, tx: signedTransaction)
    }

}


