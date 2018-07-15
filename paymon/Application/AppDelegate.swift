//
//  AppDelegate.swift
//  paymon
//
//  Created by Vladislav on 11/08/2017.
//  Copyright © 2017 Paymon. All rights reserved.
//

import UIKit
import UserNotifications
import web3swift
import Geth
//@UIApplicationMain
class AppDelegate: BRAppDelegate, NotificationManagerListener {

    var keystore = KeystoreService()

//    var window: UIWindow?
    var willAuth = false;
    var vc: UIViewController? = nil

    private func authByToken() {
        if User.isAuthenticated {
            return
        }
        if let vc = vc {
            let auth = RPC.PM_authToken()
            auth.token = User.currentUser!.token
            let _ = NetworkManager.instance.sendPacket(auth) { p, e in
                self.willAuth = false

                DispatchQueue.main.async {
                    if e != nil || !(p is RPC.PM_userFull) {
                        User.clearConfig()
                        let startView = vc.storyboard?.instantiateViewController(withIdentifier: "StartViewController") as! StartViewController
                        vc.present(startView, animated: true)
                    } else {
                        User.isAuthenticated = true
                        User.currentUser = (p as! RPC.PM_userFull)
                        User.saveConfig()
                        User.loadConfig()
                        if let rootView = UIApplication.shared.keyWindow?.rootViewController {
                            if rootView is TabsViewController {

                            } else {
                                let tabBar = vc.storyboard?.instantiateViewController(withIdentifier: "TabsView") as! TabsViewController
//                        tabBar.selectedIndex = 1
                                vc.present(tabBar, animated: true)

//                                UNUserNotificationCenter.current().delegate = self
                                UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert]) { (granted, error) in
                                    if granted {
                                        self.registerCategory()
                                    }
                                }
                            }
                        }
                        NotificationManager.instance.postNotificationName(id: NotificationManager.userAuthorized)
                        NetworkManager.instance.sendFutureRequests()
                    }
                }
            }
        }
    }

    func registerCategory() -> Void{

        let callNow = UNNotificationAction(identifier: "call", title: "Call now", options: [.foreground])
        let clear = UNNotificationAction(identifier: "clear", title: "Clear", options: [.foreground])
        let category : UNNotificationCategory = UNNotificationCategory.init(identifier: "CALLINNOTIFICATION", actions: [callNow, clear], intentIdentifiers: [], options: [])

        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories([category])

    }

//    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//        print("didReceive")
//        completionHandler()
//    }
//
//    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        print("willPresent")
//        completionHandler([.badge, .alert, .sound])
//    }

    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
//        let dec = Decimal(string: "2.2041")
//        print(dec!.description)

        User.loadConfig()

        if vc == nil {
            vc = window?.rootViewController ?? nil
        }

        NotificationManager.instance.addObserver(self, id: NotificationManager.didConnectedToServer)
        NotificationManager.instance.addObserver(self, id: NotificationManager.didDisconnectedFromServer)
        NotificationManager.instance.addObserver(self, id: NotificationManager.didEstablishedSecuredConnection)
        NotificationManager.instance.addObserver(self, id: NotificationManager.authByTokenFailed)

        //setup ether
        loadEthenWallet()
        return true
    }
    func loadEthenWallet() {
        //Choose your namespace and password
        guard let _ = UserDefaults.instance.getEthernAddress() else {
            let passphrase = "qwerty"
            let config = EthAccountConfiguration(namespace: "walletA", password: passphrase)

            //Call launch with configuration to create a keystore and account
            //keystoreA: The encrypted private and public key for wallet A
            //accountA : An Ethereum account
            var (keystore, account): (GethKeyStore?,GethAccount?) = EthAccountCoordinator.default.launch(config)
            UserDefaults.instance.setEthernAddress(value: account?.getAddress().getHex())
            KeystoreService().keystore = keystore
            self.keystore.keystore = keystore
            Keychain().passphrase = passphrase
            let jsonKey = try? keystore?.exportKey(account, passphrase: passphrase, newPassphrase: passphrase)
            let keychain = Keychain()
            keychain.jsonKey = jsonKey!
            keychain.passphrase = passphrase
            return
        }

    }
    
    override func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    override func applicationDidEnterBackground(_ application: UIApplication) {
        NetworkManager.instance.reconnect()
        User.isAuthenticated = false
    }

    override func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        if vc == nil {
            vc = window?.rootViewController ?? nil
        }

        if User.currentUser != nil && !User.isAuthenticated {
            if willAuth {
                authByToken()
            } else {
                willAuth = true
            }
        }
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    override func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func didReceivedNotification(_ id: Int, _ args: [Any]) {
        if id == NotificationManager.didEstablishedSecuredConnection {
            if  User.currentUser != nil && !User.isAuthenticated {
                if willAuth {
                    authByToken()
                } else {
                    willAuth = true
                }
            }
        } else if id == NotificationManager.didDisconnectedFromServer {
            if !User.isAuthenticated {
                willAuth = false
            }
        } else if id == NotificationManager.authByTokenFailed {
            User.clearConfig()
            if let vc = vc {
                vc.dismiss(animated: true, completion: nil)
                let startView = vc.storyboard?.instantiateViewController(withIdentifier: "StartViewController") as! StartViewController
                vc.present(startView, animated: true)
            }
        }
    }

    override func registerForPushNotifications() {
        super.registerForPushNotifications()
    }

    override func updatePlatform(onComplete: (() -> ())!) {
        super.updatePlatform(onComplete: onComplete)
    }

//    override func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
//        print(url.absoluteString)
//        print(url.path)
//        print(url.pathComponents)
//        return true
//    }
//
//    override func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
//        super.application(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completionHandler)
//    }
    override func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
//        print(2)
        return super.application(application, willContinueUserActivityWithType: userActivityType)
    }

    override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
//        print(3)
        return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }

    override func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any]) -> Bool {
        if let host = url.host {
            var params:[String:Any] = [:]
            if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
                queryItems.forEach { q in
                    let k = q.name
                    if let v = q.value {
                        if let i = Int32(v) {
                            params[k] = i
                        } else {
                            params[k] = v
                        }
                    } else {
                        params[k] = nil
                    }
                }
            }
//            print(params)

            switch host {
                case "chat":
                    print("got chat")
                case "referal":
                    print("got referal")
                    if let code = params["code"] as? String {
                        let postReferal = RPC.PM_postReferal()
                        postReferal.code = code
                        NetworkManager.instance.sendPacketNowOrLater(postReferal) { p, e in
                            guard p is RPC.PM_boolTrue else {
                                if let vc = self.window?.rootViewController?.presentedViewController {
                                    DispatchQueue.main.async {
                                        let alert = UIAlertController(title: "Failed to confirm referal URL", message: nil, preferredStyle: UIAlertControllerStyle.alert)
                                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default))
                                        vc.present(alert, animated: true)
                                    }
                                }
                                return
                            }
                        }
                    }
                default:
                    return false
            }
        }
//        print(url.absoluteString)
//        print(url.baseURL)
//        print(url.relativePath)
//        print(url.query)
//        print(url.host)
//        print(url.pathComponents)
//        print(options)
        return true
    }
}

