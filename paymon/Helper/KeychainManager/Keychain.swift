//
//  Keychain.swift
//  paymon
//
//  Created by Jogendar Singh on 27/06/18.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import Foundation

import UIKit
import Security

class Keychain {

    let serviceName = "ethereum-wallet"

    private let kSecClassGenericPasswordValue = String(format: kSecClassGenericPassword as String)
    private let kSecClassValue = String(format: kSecClass as String)
    private let kSecAttrServiceValue = String(format: kSecAttrService as String)
    private let kSecValueDataValue = String(format: kSecValueData as String)
    private let kSecMatchLimitValue = String(format: kSecMatchLimit as String)
    private let kSecReturnDataValue = String(format: kSecReturnData as String)
    private let kSecMatchLimitOneValue = String(format: kSecMatchLimitOne as String)
    private let kSecAttrAccountValue = String(format: kSecAttrAccount as String)
    private let kSecAttrAccessibleValue = String(format: kSecAttrAccessible as String)

    func set(_ data: Data?, for key: String) {

        guard let data = data else {
            delete(for: key)
            return
        }

        var query = generateQuery(for: key)

        SecItemDelete(query as CFDictionary)

        query.removeValue(forKey: kSecReturnDataValue)
        query.updateValue(data, forKey: kSecValueDataValue)
        query.updateValue(kSecAttrAccessibleWhenUnlockedThisDeviceOnly, forKey: kSecAttrAccessibleValue)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            return
        }
    }

    func get(for key: String) -> Data? {

        let query = generateQuery(for: key)

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        guard status == errSecSuccess, let data = dataTypeRef as? Data else {
            return nil
        }

        return data
    }

    func generateQuery(for key: String) -> [String: Any] {
        return [
            kSecClassValue: kSecClassGenericPasswordValue,
            kSecAttrServiceValue: serviceName,
            kSecAttrAccountValue: key,
            kSecReturnDataValue: kCFBooleanTrue
        ]
    }
}

// MARK: - Keychain hepler bilders

extension Keychain {

    // MARK: - Data
    func getData(key: KeychainKeys) -> Data? {
        return get(for: key.rawValue)
    }

    func setData(_ value: Data?, for key: KeychainKeys) {
        set(value, for: key.rawValue)
    }

    // MARK: - String
    func getString(for key: KeychainKeys) -> String? {
        guard let data = get(for: key.rawValue),
            let value = String(data: data, encoding: .utf8) else {
                return nil
        }
        return value
    }

    func setString(_ value: String?, for key: KeychainKeys) {
        let data = value?.data(using: .utf8)
        set(data, for: key.rawValue)
    }

    // MARK: - Bool
    func getBool(for key: KeychainKeys) -> Bool {
        guard let _ = getString(for: key) else {
            return false
        }
        return true
    }

    func setBool(_ value: Bool, for key: KeychainKeys) {
        setString(value ? "true" : nil, for: key)
    }


    // MARK: - Helpers
    func exist(_ key: KeychainKeys) -> Bool {
        return get(for: key.rawValue) != nil
    }

    func delete(for key: String) {
        let query = generateQuery(for: key)
        SecItemDelete(query as CFDictionary)
    }

}
