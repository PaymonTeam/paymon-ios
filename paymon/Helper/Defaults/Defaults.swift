//
//  Defaults.swift
//  paymon
//
//  Created by Jogendar Singh on 08/07/18.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import UIKit

let appDelegate: AppDelegate = (UIApplication.shared.delegate as? AppDelegate)!

final class Defaults: NSObject {

    class var chain: Chain {
        get {
            let raw: String =  get(forKey: .chain, fallback: Chain.mainnet.rawValue)
            return Chain(rawValue: raw)!
        }

        set {
            set(value: newValue.rawValue, forKey: .chain)
        }
    }

    class var mode: SyncMode {
        get {
            let raw: Int = get(forKey: .mode, fallback: SyncMode.standard.rawValue)
            return SyncMode(rawValue: raw)!
        }

        set {
            set(value: newValue.rawValue, forKey: .mode)
        }
    }

    class var isWalletCreated: Bool {
        get {
            return getBool(forKey: .isWalletCreated)
        }

        set {
            set(value: newValue, forKey: .isWalletCreated)
        }
    }

    class func deleteAll() {
        for key in Keys.allValues {
            UserDefaults.standard.removeObject(forKey: key.rawValue)
        }
    }
}

private extension Defaults {

    enum Keys: String, EnumCollection {
        case chain = "chainKey"
        case mode = "syncMode"
        case isWalletCreated = "isWalletCreated"
    }

    static func set<T: Any>(value: T, forKey key: Keys) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
        UserDefaults.standard.synchronize()
    }

    static func get<T: Any>(forKey key: Keys, fallback: T) -> T {
        if let value = UserDefaults.standard.value(forKey: key.rawValue) as? T {
            return value
        }

        return fallback
    }

    static func getBool(forKey key: Keys) -> Bool {
        return UserDefaults.standard.bool(forKey: key.rawValue)
    }

}
