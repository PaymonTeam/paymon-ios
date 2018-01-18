//
//  BCHSender.swift
//  BreadWallet
//
//  Created by Adrian Corscadden on 2017-08-08.
//  Copyright © 2017 Aaron Voisine. All rights reserved.
//

import Foundation
import BR_Core

typealias BRTxRef = UnsafeMutablePointer<BR_Core.BR_Transaction>

private let apiClient = BRAPIClient()

@objc class BCHSender : NSObject {

    func sendBCHTransaction(walletManager: BRWalletManager, address: String, feePerKb: UInt64, callback: @escaping (String?) -> Void) {
        let genericError = "Your account does not contain any BCH, or you received BCH after the fork.";
        guard let txData = walletManager.wallet?.bCashSweepTx(to: address, feePerKb: feePerKb)?.data else { assert(false, "No Tx Data"); return callback(genericError) }
        guard let txCount = walletManager.wallet?.allTransactions.count else { assert(false, "Could not get txCount"); return callback(genericError) }
        guard let mpk = walletManager.masterPublicKey?.masterPubKey else { assert(false, "Count not get mpkData"); return callback("Couldn't prepare transaction.") }
        guard let balance = walletManager.wallet?.balance else { return callback(genericError) }

        guard let tx = txData.withUnsafeBytes({ (ptr: UnsafePointer<UInt8>) -> BRTxRef? in
            return BR_TransactionParse(ptr, txData.count)
        }) else { assert(false, "Could not parse Tx Data"); return callback(genericError) }
        
        defer { BR_TransactionFree(tx) }
        let wallet = BR_WalletNew(nil, 0, mpk)
        defer { BR_WalletFree(wallet) }
        BR_WalletUnusedAddrs(wallet, nil, UInt32(txCount), 0)
        BR_WalletUnusedAddrs(wallet, nil, UInt32(txCount), 1)


        guard let seedData = walletManager.seed(withPrompt: "Authorize sending BCH Balance", forAmount: balance) else {
            return callback(genericError)
        }
        var seed: BR_Core.UInt512_t = seedData.withUnsafeBytes { $0.pointee }
        BR_WalletSignTransaction(wallet, tx, 0x40, &seed, MemoryLayout<BR_Core.UInt512_t>.stride)
        let txHash = tx.pointee.txHash
        print("b-cash txHash: \(txHash.description)")
        guard let txBytes = tx.bytes else { return callback(genericError) }
        print("CL 5")
        apiClient.publishBCHTransaction(txData: Data(bytes: txBytes, count: txBytes.count), callback: { errorMessage in
            if errorMessage == nil {
                UserDefaults.standard.set(txHash.description, forKey: "BCHTxHashKey")
            }
            callback(errorMessage)
        })

    }

}

extension BRAPIClient {
    func publishBCHTransaction(txData: Data, callback: @escaping (String?)->Void) {
        var req = URLRequest(url: url("/bch/publish-transaction"))
        req.httpMethod = "POST"
        req.setValue("application/bchdata", forHTTPHeaderField: "Content-Type")
        req.httpBody = txData
        dataTaskWithRequest(req as URLRequest, authenticated: true, retryCount: 0) { (dat, resp, er) in
            if let statusCode = resp?.statusCode {
                if statusCode >= 200 && statusCode < 300 {
                    callback(nil)
                } else if let data = dat, let errorString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    callback(errorString as String)
                } else {
                    callback("\(statusCode)")
                }
            }
            }.resume()
    }
}

extension UnsafeMutablePointer where Pointee == BR_Core.BR_Transaction {
    // serialized transaction (blockHeight and timestamp are not serialized)
    var bytes: [UInt8]? {
        var bytes = [UInt8](repeating:0, count: BR_TransactionSerialize(self, nil, 0))
        guard BR_TransactionSerialize(self, &bytes, bytes.count) == bytes.count else { return nil }
        return bytes
    }
}

extension Data {
    var masterPubKey: BR_MasterPubKey? {
        guard self.count >= (4 + 32 + 33) else { return nil }
        var mpk = BR_MasterPubKey()
        mpk.fingerPrint = self.subdata(in: 0..<4).withUnsafeBytes({ $0.pointee })
        mpk.chainCode = self.subdata(in: 4..<(4 + 32)).withUnsafeBytes({ $0.pointee })
        mpk.pubKey = self.subdata(in: (4 + 32)..<(4 + 32 + 33)).withUnsafeBytes({ $0.pointee })
        return mpk
    }
}

extension BR_Core.UInt256_t : CustomStringConvertible {
    public var description: String {
        return String(format:"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x" +
            "%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                      self.u8.31, self.u8.30, self.u8.29, self.u8.28, self.u8.27, self.u8.26, self.u8.25, self.u8.24,
                      self.u8.23, self.u8.22, self.u8.21, self.u8.20, self.u8.19, self.u8.18, self.u8.17, self.u8.16,
                      self.u8.15, self.u8.14, self.u8.13, self.u8.12, self.u8.11, self.u8.10, self.u8.9, self.u8.8,
                      self.u8.7, self.u8.6, self.u8.5, self.u8.4, self.u8.3, self.u8.2, self.u8.1, self.u8.0)
    }
}
