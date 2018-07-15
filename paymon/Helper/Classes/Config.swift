//
// Created by Vladislav on 23/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import Foundation

class Config {
    open static let BUILD_DEBUG = true
    open static let BUILD_PRODUCTION = true
    open static let HOST = BUILD_DEBUG ? "91.226.80.26" : "91.226.80.26"
    open static let PORT:UInt16 = BUILD_PRODUCTION ? 7966 : 7968

    public static let SETTINGS_NOTIFICATION = "settings_notification_"
    public static let SETTINGS_NOTIFICATION_WORRY = "settings_notification_worry"
    public static let SETTINGS_NOTIFICATION_VIBRATION = "settings_notification_vibration"
    public static let SETTINGS_NOTIFICATION_TRANSACTIONS = "settings_notification_transactions"
    public static let SETTINGS_NOTIFICATION_SOUND = "settings_notification_sound"

    public static let SETTINGS_SECURITY = "settings_security_"
    public static let SETTINGS_SECURITY_PASSWORD_PROTECTED = "settings_security_password_protected"
    public static let SETTINGS_SECURITY_PASSWORD_PROTECTED_STRING = "settings_security_password_protected_string"

    public static let YM_ACCESS_TOKEN = "ym_access_token"

    public static var QR_CODE_VALUE = ""
    public static var QR_CODE_ADDRESS = ""

    public static let WEB_CONTENT = "http://"
    public static let WEB_CONTENT_2 = "https://"

    public static let BITCOIN_WALLET = "bitcoin:1"
    public static let BITCOIN_WALLET_2 = "BITCOIN:-"
    public static let BITCOIN_WALLET_3 = "1"
    public static let BITCOIN_WALLET_4 = "3"
    public static let BITCOIN_WALLET_5 = "bitcoin:3"

    public static let ETHEREUM_WALLET = "ethereum:0x"
    public static let ETHEREUM_WALLET_2 = " 0x"
    public static let ETHEREUM_WALLET_3 = "0x"

}
