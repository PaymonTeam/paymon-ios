//
//  AuthTableViewController.swift
//  paymon
//
//  Created by maks on 07.10.17.
//  Copyright © 2017 Paymon. All rights reserved.
//

import UIKit

extension UIView {

    func shake() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = [self.center.x - 10, self.center.y]
        animation.toValue = [self.center.x + 10, self.center.y]
        self.layer.add(animation, forKey: "position")
    }

}

class AuthTableViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var passwordTableViewCell: UITableViewCell!
    @IBOutlet weak var loginTableViewCell: UITableViewCell!

    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginTextField: UITextField!

    private var observerLogin: NSObjectProtocol!

    @objc func endEditing() {
        self.view.endEditing(true)
    }

    func auth(notification: Notification) {

        let loginString = loginTextField.text!
        let passwordString = passwordTextField.text!

        if loginString.isEmpty {
            loginTableViewCell.shake()
            return
        }

        if passwordString.isEmpty {
            passwordTableViewCell.shake()
            return
        }

        NetworkManager.instance.auth(login: loginString, password: passwordString, callback: { p, e in
            if let user = p as? RPC.PM_userFull {

                if user.confirmed {
                    print("User has logged in")
                    User.currentUser = user
                    User.isAuthenticated = true
                    User.saveConfig()
                    User.loadConfig()

                    print("true login")

                    NotificationCenter.default.post(name: NSNotification.Name("hideIndicatorLogin"), object: nil)

                    let tabsView = self.storyboard?.instantiateViewController(withIdentifier: "TabsView") as! TabsViewController
                    self.present(tabsView, animated: true)
                } else {
                    NotificationCenter.default.post(name: NSNotification.Name("hideIndicatorLogin"), object: nil)
                    NotificationCenter.default.post(name: NSNotification.Name("loginFalse"), object: nil)

                    let alert = UIAlertController(title: "Confirmation email".localized,
                            message: String(format: NSLocalizedString("You did not verify your account by email \n %@ \n\n Send mail again?".localized, comment: ""), user.email),
                            preferredStyle: .alert)

                    alert.addAction(UIAlertAction(title: "Cancel".localized, style: .default, handler: { (action) in
                        User.clearConfig()
                        NetworkManager.instance.reset()
                        NetworkManager.instance.reconnect()
                    }))

                    alert.addAction(UIAlertAction(title: "Send".localized, style: .default, handler: { (action) in
                        //Todo Отправлять email на почту еще раз

                        let resendEmail = RPC.PM_resendEmail()
                        if !user.confirmed {
                            NetworkManager.instance.sendPacket(resendEmail) { response, error in
                                if response is RPC.PM_boolTrue {
                                    print("Я переслал письмо")
//                                    NetworkManager.instance.reconnect()
                                    let alert = UIAlertController(title: "Confirmation email".localized,
                                            message: "The letter was sent".localized,
                                            preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: { (action) in

                                    }))
                                    DispatchQueue.main.async {
                                        self.present(alert, animated: true)
                                    }
                                } else {
                                    let alert = UIAlertController(title: "Confirmation email".localized,
                                            message: "The email was not sent. Check your internet connection.".localized,
                                            preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: { (action) in

                                    }))
                                    DispatchQueue.main.async {
                                        self.present(alert, animated: true)
                                    }

                                    print("Я не смог отправить письмо")
                                    print(error)
                                }

                                User.clearConfig()
                                NetworkManager.instance.reset()
                                NetworkManager.instance.reconnect()
                            }
                        }
                    }))
                    DispatchQueue.main.async {
                        self.present(alert, animated: true, completion: nil)
                    }
                }
//                self.dismiss(animated: true, completion: {
//                    NotificationManager.instance.postNotificationName(id: NotificationManager.userDidLoggedIn)
//
//                })

            } else if let error = e {
                print("false login")

                NotificationCenter.default.post(name: NSNotification.Name("hideIndicatorLogin"), object: nil)
                NotificationCenter.default.post(name: NSNotification.Name("loginFalse"), object: nil)
                print("User login failed")

                let msg = (error.code == RPC.ERROR_AUTH ? "Invalid login or password".localized : "Unknown error")
                let alert = UIAlertController(title: "Login Failed".localized, message: msg, preferredStyle: UIAlertControllerStyle.alert)
                let alertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
                    (UIAlertAction) -> Void in
                }
                alert.addAction(alertAction)
                DispatchQueue.main.async {
                    self.present(alert, animated: true) {
                        () -> Void in
                    }
                }
            }
        })
    }

    @objc func textFieldDidChanged(_ textField: UITextField) {
        if !(loginTextField.text?.isEmpty)! && !(passwordTextField.text?.isEmpty)! {

            NotificationCenter.default.post(name: NSNotification.Name("canLoginTrue"), object: nil)

        } else {

            NotificationCenter.default.post(name: NSNotification.Name("canLoginFalse"), object: nil)

        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        observerLogin = NotificationCenter.default.addObserver(forName: NSNotification.Name("login"), object: nil, queue: nil, using: auth)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        switch (section) {
        case 0: return "Enter your login and password".localized
        default: return "Enter your login and password".localized
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        loginTextField.delegate = self
        passwordTextField.delegate = self

        loginTextField.placeholder = "Login".localized
        passwordTextField.placeholder = "Password".localized

        let tapper = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tapper.cancelsTouchesInView = false
        view.addGestureRecognizer(tapper)

        loginTextField.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(observerLogin)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == loginTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            NotificationCenter.default.post(name: NSNotification.Name("returnKeyLogin"), object: nil)
        }

        return true
    }
}

