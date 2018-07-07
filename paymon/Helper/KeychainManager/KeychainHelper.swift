//
//  KeychainHelper.swift
//  paymon
//
//  Created by Jogendar Singh on 27/06/18.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import Foundation


import UIKit
// MARK: - Keychain errors
protocol CustomError: Error {
    typealias ErrorInfo = (title: String?, message: String?, showing: Bool)
    var description: ErrorInfo? { get }
}

extension CustomError {
    var criticalError: ErrorInfo {
        return (title: "Critical error", message: "Something went wront. Please contact with developers", showing: true)
    }
}

enum KeychainError: CustomError {

    case noJsonKey
    case noPassphrase
    case keyIsInvalid

    var description: CustomError.ErrorInfo? {
        switch self {
        case .noJsonKey:
            return criticalError
        case .noPassphrase:
            return criticalError
        case .keyIsInvalid:
            return (title: "Invalid key", message: "The provided key is not valid", showing: true)
        }
    }

}

extension Keychain {

    enum KeychainKeys: String, EnumCollection {
        case jsonKey = "json_key_data"
        case passphrase = "passphrase"
    }

    var isAccountBackuped: Bool {
        return exist(.jsonKey)
    }

    var jsonKey: Data? {
        get {
            return getData(key: .jsonKey)
        }
        set {
            setData(newValue, for: .jsonKey)
        }
    }

    var passphrase: String? {
        get {
            return getString(for: .passphrase)
        }

        set {
            setString(newValue, for: .passphrase)
        }
    }
    var keystore: String? {
        get {
            return getString(for: .passphrase)
        }

        set {
            setString(newValue, for: .passphrase)
        }
    }

    // MARK: - Getters

    func getJsonKey() throws -> Data {
        guard let jsonKey = jsonKey else {
            throw KeychainError.noJsonKey
        }
        return jsonKey
    }

    func getPassphrase() throws -> String {
        guard let passphrase = passphrase else {
            throw KeychainError.noPassphrase
        }
        return passphrase
    }

    var isAuthorized: Bool {
        return passphrase != nil && jsonKey != nil
    }

    // MARK: - Utils

    func deleteAll() {
        for key in KeychainKeys.allValues {
            delete(for: key.rawValue)
        }
    }

}
