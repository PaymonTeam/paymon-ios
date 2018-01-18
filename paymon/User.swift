//
// Created by Vladislav on 23/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import Foundation

class User {
    public static var currentUser: RPC.UserObject?
    public static var isAuthenticated = false
    public static var notificationSwitchWorry = true
    public static var notificationSwitchVibration = true
    public static var notificationSwitchTransactions = false
    public static var notificationSound = ""
    public static var securitySwitchPasswordProtected = false
    public static var securityPasswordProtectedString = ""

    public static var notificationSettings: UserDefaults = UserDefaults()
    public static var securitySettings: UserDefaults = UserDefaults()
    public static var moneyDefaults: UserDefaults = UserDefaults(suiteName: "pm_money")!
    let basicSettings = UserDefaults.standard
    let moneySettings = UserDefaults.standard
    private static var _ymAccessToken: String?

    public static var ymAccessToken: String? {
        get {
            if _ymAccessToken == nil {
                _ymAccessToken = moneyDefaults.string(forKey: Config.YM_ACCESS_TOKEN)
            }
            return _ymAccessToken
        }
        set {
            _ymAccessToken = newValue
            if _ymAccessToken != nil {
                moneyDefaults.set(_ymAccessToken!, forKey: Config.YM_ACCESS_TOKEN)
            }
        }
    }

    public static func saveConfig() {
        if currentUser != nil {
            let stream = SerializedStream()
            currentUser!.serializeToStream(stream: stream!)
            let userString = stream!.out.base64EncodedString()
            KeychainWrapper.standard.set(userString, forKey: "user", withAccessibility: KeychainItemAccessibility.always)
        } else {
            KeychainWrapper.standard.removeObject(forKey: "user")
        }
    }

    public static func saveNotificationSettings() {
        notificationSettings.addSuite(named: Config.SETTINGS_NOTIFICATION + String(currentUser!.id))

        notificationSettings.set(notificationSwitchWorry, forKey: Config.SETTINGS_NOTIFICATION_WORRY)
        notificationSettings.set(notificationSwitchVibration, forKey: Config.SETTINGS_NOTIFICATION_VIBRATION)
        notificationSettings.set(notificationSwitchTransactions, forKey: Config.SETTINGS_NOTIFICATION_TRANSACTIONS)
        notificationSettings.set(notificationSound, forKey: Config.SETTINGS_NOTIFICATION_SOUND)

        print(notificationSettings)
    }

    public static func saveSecuritySettings() {
        securitySettings.addSuite(named: Config.SETTINGS_SECURITY + String(currentUser!.id))

        securitySettings.set(securitySwitchPasswordProtected, forKey: Config.SETTINGS_SECURITY_PASSWORD_PROTECTED)
        securitySettings.set(securityPasswordProtectedString, forKey: Config.SETTINGS_SECURITY_PASSWORD_PROTECTED_STRING)
    }

    public static func loadConfig() {
        print("load config")

        if currentUser == nil {
//            let data = SerializedStream()
//            currentUser!.serializeToStream(stream: data!)
//            let userString = data!.out.base64EncodedString()
//            KeychainWrapper.standard.set(userString, forKey: "user", withAccessibility: KeychainItemAccessibility.always)
            if let retrievedString = KeychainWrapper.standard.string(forKey: "user") {
                let data = Data(base64Encoded: retrievedString)
                let stream = SerializedStream(data: data)
                if let deserialize = try? RPC.UserObject.deserialize(stream: stream!, constructor: stream!.readInt32(nil)) {
                    if (deserialize is RPC.PM_userFull) {
                        currentUser = deserialize as! RPC.PM_userFull;
                        print("User loaded: \(currentUser!.login!)")
                    } else {
                        return
                    }
                } else {
                    return
                }
                stream!.close()
            } else {
                return
            }
        }

        notificationSettings.addSuite(named: Config.SETTINGS_NOTIFICATION + String(currentUser!.id))
        securitySettings.addSuite(named: Config.SETTINGS_SECURITY + String(currentUser!.id))

        notificationSwitchWorry = notificationSettings.object(forKey: Config.SETTINGS_NOTIFICATION_WORRY) as? Bool ?? true
        notificationSwitchVibration = notificationSettings.object(forKey: Config.SETTINGS_NOTIFICATION_VIBRATION) as? Bool ?? true
        notificationSwitchTransactions = notificationSettings.object(forKey: Config.SETTINGS_NOTIFICATION_TRANSACTIONS) as? Bool ?? false
        notificationSound = notificationSettings.object(forKey: Config.SETTINGS_NOTIFICATION_SOUND) as? String ?? "Note.mp3"

        print("\(notificationSound)")

        securitySwitchPasswordProtected = securitySettings.object(forKey: Config.SETTINGS_SECURITY_PASSWORD_PROTECTED) as? Bool ?? false
        securityPasswordProtectedString = securitySettings.string(forKey: Config.SETTINGS_SECURITY_PASSWORD_PROTECTED_STRING) ?? ""


        //

//        if let manager = BRWalletManager.sharedInstance() {
//            let str:String = "123\(manager.format!.currencyDecimalSeparator!)456"
//            let r1 = 1...2
//            var charset = CharacterSet.decimalDigits
//            charset.insert(charactersIn: manager.format!.currencyDecimalSeparator!)
//            let numberFormatter: NumberFormatter = NumberFormatter()
//            numberFormatter.isLenient = true
//            numberFormatter.numberStyle = .currency
//            numberFormatter.generatesDecimalNumbers = true
//            numberFormatter.maximumFractionDigits = 2
//            numberFormatter.minimumFractionDigits = 0
//            let r2 = str.range(of: numberFormatter.currencyDecimalSeparator)!
//            let i = str.range(of: numberFormatter.currencyDecimalSeparator)!.lowerBound.encodedOffset
//            let r3 = str.rangeOfCharacter(from: charset, options: .backwards)!
//            print(str)
//            print(r1)
//            print(r2)
//            print(i)
//            print(r3)
//        }
//        }

        MediaManager.instance.prepare()
    }

    public static func clearConfig() {
        isAuthenticated = false
        KeychainWrapper.standard.removeObject(forKey: "user")
        currentUser = nil
        notificationSwitchWorry = true
        notificationSwitchVibration = true
        notificationSwitchTransactions = false
        notificationSound = "Note.mp3"
        securitySwitchPasswordProtected = false
        securityPasswordProtectedString = ""
        ymAccessToken = nil
        moneyDefaults.removeObject(forKey: Config.YM_ACCESS_TOKEN)
    }
}
