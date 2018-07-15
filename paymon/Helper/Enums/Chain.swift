//
//  EnumChain.swift
//  paymon
//
//  Created by Jogendar Singh on 01/07/18.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//
import Geth

enum Chain: String {

    case mainnet
    case ropsten
    case rinkeby

    static var `default`: Chain {
        return .mainnet
    }

    var chainId: Int64 {
        switch self {
        case .mainnet:
            return 1
        case .ropsten:
            return 3
        case .rinkeby:
            return 4
        }
    }

    var netStats: String? {
        switch self {
        case .rinkeby:
            return "flypaper:Respect my authoritah!@stats.rinkeby.io"
        default:
            return nil
        }
    }

    var enode: String? {
        switch self {
        case .mainnet:
            return nil
        case .ropsten:
            return Ethereum.ropstenEnodeRawUrl
        case .rinkeby:
            return Ethereum.rinkebyEnodeRawUrl
        }
    }

    var genesis: String {
        switch self {
        case .mainnet:
            return GethMainnetGenesis()
        case .ropsten:
            return GethTestnetGenesis()
        case .rinkeby:
            return GethRinkebyGenesis()
        }
    }

    var description: String {
        return "\(self)"
    }

    var localizedDescription: String {
        switch self {
        case .mainnet:
            return "Mainnet"
        case .ropsten:
            return "Ropsten Testnet"
        case .rinkeby:
            return "Rinkeby Testnet"
        }
    }

    var path: String {
        return "/.\(description)"
    }

    var etherscanApiUrl: String {
        switch self {
        case .mainnet:
            return "api.etherscan.io"
        case .ropsten:
            return "ropsten.etherscan.io"
        case .rinkeby:
            return "rinkeby.etherscan.io"
        }
    }

    var clientUrl: String {
        switch self {
        case .mainnet:
            return "https://mainnet.infura.io"
        case .ropsten:
            return "https://ropsten.infura.io"
        case .rinkeby:
            return "https://rinkeby.infura.io"
        }
    }

    var etherscanUrl: String {
        switch self {
        case .mainnet:
            return "https://etherscan.io"
        case .ropsten:
            return "https://ropsten.etherscan.io"
        case .rinkeby:
            return "https://rinkeby.etherscan.io"
        }
    }

    var isMainnet: Bool {
        return self == .mainnet
    }

    static func all() -> [Chain] {
        return [.mainnet, .ropsten, .rinkeby]
    }

}
