//
//  UserDefaults.swift
//  paymon
//
//  Created by Jogendar Singh on 27/06/18.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import UIKit

extension UserDefaults {

    // Make singleton object.
    static let instance = UserDefaults()

    // MARK: - Set/Get user token
    func setEthernAddress(value: String?) {
        if value != nil {
            UserDefaults.standard.set(value, forKey: UserDefaultKey.ethernAddress)
        } else {
            UserDefaults.standard.removeObject(forKey: UserDefaultKey.ethernAddress)
        }
        UserDefaults.standard.synchronize()
    }

    func getEthernAddress() -> String? {
        return UserDefaults.standard.value(forKey: UserDefaultKey.ethernAddress) as? String
    }

    // clear guest related data
    func clearGuestDefaultData() {

    }

}

