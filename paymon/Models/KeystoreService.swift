//
//  KeystoreService.swift
//  paymon
//
//  Created by Jogendar Singh on 07/07/18.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import Geth
enum EthereumError: CustomError {

    case nodeStartFailed(error: NSError)
    case accountExist
    case couldntGetNonce
    case alreadySubscribed

    var description: ErrorInfo? {
        switch self {
        case .nodeStartFailed(let error):
            return ("Starting node error", error.localizedDescription, true)
        case .accountExist:
            return (nil, "Account already exist", true)
        default:
            return nil
        }
    }

}
protocol KeystoreServiceProtocol {
    func getAccount(at index: Int) throws -> GethAccount
    func createAccount(passphrase: String) throws -> GethAccount
    func jsonKey(for account: GethAccount, passphrase: String) throws -> Data
    func jsonKey(for account: GethAccount, passphrase: String, newPassphrase: String) throws -> Data
    func restoreAccount(with jsonKey: Data, passphrase: String) throws -> GethAccount
    func deleteAccount(_ account: GethAccount, passphrase: String) throws
    func deleteAllAccounts(passphrase: String) throws
    func signTransaction(_ transaction: GethTransaction, account: GethAccount, passphrase: String, chainId: Int64) throws -> GethTransaction
}
class KeystoreService: KeystoreServiceProtocol {

    lazy var keystore: GethKeyStore! = {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return GethNewKeyStore(documentDirectory + "/keystore", GethLightScryptN, GethLightScryptP)
    }()

    // MARK: Account managment

    func getAccount(at index: Int) throws -> GethAccount {
        return try keystore.getAccounts().get(index)
    }

    func createAccount(passphrase: String) throws -> GethAccount {
        guard keystore.getAccounts().size() == 0 else {
            throw EthereumError.accountExist
        }

        return try keystore.newAccount(passphrase)
    }

    func jsonKey(for account: GethAccount, passphrase: String) throws -> Data {
        return try keystore.exportKey(account, passphrase: passphrase, newPassphrase: passphrase)
    }

    func jsonKey(for account: GethAccount, passphrase: String, newPassphrase: String) throws -> Data {
        return try keystore.exportKey(account, passphrase: passphrase, newPassphrase: newPassphrase)
    }

    func restoreAccount(with jsonKey: Data, passphrase: String) throws -> GethAccount  {
        return try keystore.importKey(jsonKey, passphrase: passphrase, newPassphrase: passphrase)
    }

    func deleteAccount(_ account: GethAccount, passphrase: String) throws {
        return try keystore.delete(account, passphrase: passphrase)
    }

    func deleteAllAccounts(passphrase: String) throws {
        let size = keystore.getAccounts().size()
        for i in 0..<size {
            let account = try getAccount(at: i)
            try keystore.delete(account, passphrase: passphrase)
        }
    }

    // MARK: Sign transaction

    func signTransaction(_ transaction: GethTransaction, account: GethAccount, passphrase: String, chainId: Int64) throws -> GethTransaction {
        let bigChainId = GethBigInt(chainId)
        return try keystore.signTxPassphrase(account, passphrase: passphrase, tx: transaction, chainID: bigChainId)
    }

}

