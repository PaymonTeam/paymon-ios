//
//  ETH.swift
//  paymon
//
//  Created by Jogendar Singh on 01/07/18.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import Foundation

struct TransactionInfo {
    let amount: Decimal
    let address: String
    let contractAddress: String?
    let gasLimit: Decimal
    let gasPrice: Decimal
}

class ETHModel: Codable{

    var BTC: Double?
    var CNY: Double?
    var ETH: Double?
    var EUR: Double?
    var GBP: Double?
    var USD: Double?

    func getValueForSelected(currency: String) -> Double? {

        switch currency {
        case "BTC":
            return self.BTC
        case "CNY":
            return self.CNY
        case "ETH":
            return self.ETH
        case "EUR":
            return self.EUR
        case "GBP":
            return self.GBP
        case "USD":
            return self.USD
        default:
            return nil
        }
    }
}

extension ETHModel {
    func getRates(success: @escaping ((_ response: ETHModel?) -> Void), failure: @escaping ((_ error: NSError?) -> Void)) {
        ConnectionManager.instance.getRates(success: { (response) in
            if let responseDict = response as? [String: Any],
                let data = responseDict["ETH"] as? [String: Any] {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: data as Any, options: JSONSerialization.WritingOptions.prettyPrinted)
                    let result = try JSONDecoder().decode(ETHModel.self, from: jsonData)
                    success(result)
                } catch let message {
                    print("JSON serialization error:" + "\(message)")
                    failure(nil)
                }
            } else {
                failure(nil)
            }
        }, failure: failure)
    }
}
