//
//  Constants.swift
//  paymon
//
//  Created by Jogendar Singh on 26/06/18.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import Foundation

struct StoryBoardIdentifier {
    static let receiveEthernVC = "ReceiveViewController"
    static let sendVCStoryID = "SendViewController"
    static let scanVCStoryID = "ScanViewControllerID"
    static let chooseCurrencyVCStoryID = "ChooseCurrencyViewController"
    static let CoinDetailsVCStoryID = "CoinDetailsViewController"
}

struct UserDefaultKey {
    static let ethernAddress = "ethernAdd"
}

struct Ethereum {
    static let rinkebyEnodeRawUrl = "enode://a24ac7c5484ef4ed0c5eb2d36620ba4e4aa13b8c84684e1b4aab0cebea2ae45cb4d375b77eab56516d34bfbd3c1a833fc51296ff084b770b94fb9028c4d25ccf@52.169.42.101:30303?discport=30304"
    static let ropstenEnodeRawUrl = "enode://a24ac7c5484ef4ed0c5eb2d36620ba4e4aa13b8c84684e1b4aab0cebea2ae45cb4d375b77eab56516d34bfbd3c1a833fc51296ff084b770b94fb9028c4d25ccf@52.169.42.101:30303?discport=30304"
}

struct Etherscan {
    static let apiKey = "1KDW41TE2CPJI7DC2UWSXUWRQ6WFUR885E"
}

struct Wallet {
    static let defaultCurrency = "USD"
    static let supportedCurrencies = ["BTC","ETH","USD","EUR","CNY","GBP"]
}

struct Common {
    static let githubUrl = "https://github.com/flypaper0/ethereum-wallet"
}

struct Send {
    static let defaultGasLimit: Decimal = 21000
    static let defaultGasLimitToken: Decimal = 53000
    static let defaultGasPrice: Decimal = 2000000000
}
