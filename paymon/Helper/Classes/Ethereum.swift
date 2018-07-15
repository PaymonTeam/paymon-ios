//
//  Ethereum.swift
//  paymon
//
//  Created by Jogendar Singh on 07/07/18.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import UIKit
import Geth

protocol SyncCoordinatorProtocol {
    func startSync(chain: Chain, delegate: SyncCoordinatorDelegate) throws
    func getClient() throws -> GethEthereumClient
}
protocol SyncCoordinatorDelegate: class {
    func syncDidChangeProgress(current: Int64, max: Int64)
    func syncDidFinished()
    func syncDidUpdateBalance(_ balanceHex: String, timestamp: Int64)
    func syncDidUpdateGasLimit(_ gasLimit: Int64)
    func syncDidReceiveTransactions(_ transactions: [GethTransaction], timestamp: Int64)
}

protocol EthereumCoreProtocol {
    func start(chain: Chain, delegate: SyncCoordinatorDelegate?) throws
}

class Ethereums: EthereumCoreProtocol {

    static let core = Ethereums()
    static let syncQueue = DispatchQueue(label: "com.ethereum-wallet.sync")

    let context: GethContext = GethNewContext()
    var syncCoordinator: SyncCoordinatorProtocol!
    var client: GethEthereumClient!
    var chain: Chain!

    private init() {}

    func start(chain: Chain, delegate: SyncCoordinatorDelegate?) throws {
        self.chain = chain
        self.client = try self.getClient()
    }

    func getClient() throws -> GethEthereumClient {
        var error: NSError?
        let client =  GethNewEthereumClient(chain.clientUrl, &error)
        guard error == nil else {
            throw error!
        }
        return client!
    }

}


