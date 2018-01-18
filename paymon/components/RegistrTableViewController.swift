//
//  RegistrTableViewController.swift
//  paymon
//
//  Created by maks on 16.11.17.
//  Copyright © 2017 Paymon. All rights reserved.
//

import UIKit

class RegistrTableViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var cellEmail: UITableViewCell!
    @IBOutlet weak var cellRepeatPassword: UITableViewCell!
    @IBOutlet weak var cellPassword: UITableViewCell!
    @IBOutlet weak var cellLogin: UITableViewCell!
    @IBOutlet weak var registrButton: UIButton!
    @IBOutlet weak var inviteCodeTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var repeatPasswordTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var loginLabel: UILabel!
    @IBOutlet weak var repeatPasswordLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var inviteCodeLabel: UILabel!

    private var observerRegistr: NSObjectProtocol!

    var matched = false
    var passwordValidated = false
    var passwordStringValidated = ""

    var loginValid = false;
    var passwordValid = false;
    var repeatPasswordValid = false;
    var emailValid = false;

    var loginString = ""
    var passwordString = ""
    var emailString = ""
    var inviteCodeString = ""

    let labelList = ["Login".localized, "Password".localized, "Repeat".localized, "E-mail".localized, "Invite code".localized]
    let placeholderList = ["At least 3 symbols".localized, "At least 8 symbols".localized, "Required".localized, "Required".localized, "Optional".localized]

    @objc func endEditing() {
        self.view.endEditing(true)
    }

    func validateLogin(_ newText:String) -> Bool {
        if newText.utf8.count < 3 { return false }

        let regexStr = "^[a-zA-Z0-9-_\\.]+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regexStr)
        return predicate.evaluate(with: newText)
    }

    func validatePassword(_ newText:String) -> Bool {
        let matched = newText.utf8.count >= 8
        passwordStringValidated = newText
        passwordValidated = matched
        return matched
    }

    func validatePasswordRepeat(_ newText:String) -> Bool {
        return passwordValidated && (newText == passwordStringValidated)
    }

    func validateEmail(_ newText:String) -> Bool {
        let regexStr = ".+@.+\\..+"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regexStr)
        return predicate.evaluate(with: newText)
    }

    func registr() {

        if !self.loginValid {
            cellLogin.shake()
            return
        }

        if !self.passwordValid {
            cellPassword.shake()
            return
        }

        if !self.repeatPasswordValid {
            cellRepeatPassword.shake()
            return
        }

        if !self.emailValid {
            cellEmail.shake()
            return
        }

        let register = RPC.PM_register()
        register.login = loginString
        register.password = passwordString
        register.email = emailString
        register.walletKey = "OoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOo";
        register.inviteCode = inviteCodeString ?? "";

        let _ = NetworkManager.instance.sendPacket(register) { p,e in

            if let user = p as? RPC.PM_userFull {
                print("User has been registered")

                NotificationCenter.default.post(name: NSNotification.Name("hideIndicatorRegistr"), object: nil)

                let alertSuccess = UIAlertController(title: "Registration was successful".localized,
                        message: "Congratulations, you have successfully registered. Account activation sent to your email. Confirm account and log in.".localized,
                        preferredStyle: UIAlertControllerStyle.alert)

                alertSuccess.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) in
                    self.dismiss(animated: true)
                }))

                DispatchQueue.main.async {
                    self.present(alertSuccess, animated: true) {
                        () -> Void in
                    }
                }
//                User.currentUser = user
//                User.isAuthenticated = true
//                User.saveConfig()
//                DispatchQueue.main.async {
//                    self.controller.view.window!.rootViewController?.dismiss(animated: true, completion: nil)
//                    NotificationManager.instance.postNotificationName(id: NotificationManager.userDidLoggedIn)
//                }
            } else if e != nil {
                NotificationCenter.default.post(name: NSNotification.Name("hideIndicatorRegistr"), object: nil)
                NotificationCenter.default.post(name: NSNotification.Name("registrFalse"), object: nil)

                let alertError = UIAlertController(title: "Registration Failed".localized, message: "Такие логин или электронная почта уже используются".localized, preferredStyle: UIAlertControllerStyle.alert)
                let alertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
                    (UIAlertAction) -> Void in
                }
                alertError.addAction(alertAction)
                DispatchQueue.main.async {
                    self.present(alertError, animated: true) {
                        () -> Void in
                    }
                }
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        switch (textField) {
            case loginTextField:
                passwordTextField.becomeFirstResponder()
            case passwordTextField:
                repeatPasswordTextField.becomeFirstResponder()
            case repeatPasswordTextField:
                emailTextField.becomeFirstResponder()
            case emailTextField:
                inviteCodeTextField.becomeFirstResponder()
            case inviteCodeTextField:
                textField.endEditing(true)
            default: loginTextField.becomeFirstResponder()
        }
        if textField == loginTextField {
            passwordTextField.becomeFirstResponder()
        }

        return true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        observerRegistr = NotificationCenter.default.addObserver(forName: NSNotification.Name("registr"), object: nil, queue: nil) {
            notification in

            self.registr()
        }

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        loginLabel.text = labelList[0]
        passwordLabel.text = labelList[1]
        repeatPasswordLabel.text = labelList[2]
        emailLabel.text = labelList[3]
        inviteCodeLabel.text = labelList[4]

        loginTextField.placeholder = placeholderList[0]
        passwordTextField.placeholder = placeholderList[1]
        repeatPasswordTextField.placeholder = placeholderList[2]
        emailTextField.placeholder = placeholderList[3]
        inviteCodeTextField.placeholder = placeholderList[4]

        loginTextField.delegate = self
        passwordTextField.delegate = self
        repeatPasswordTextField.delegate = self
        emailTextField.delegate = self
        inviteCodeTextField.delegate = self

        registrButton.setTitle("Register".localized, for: .normal)

        loginTextField.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)
        repeatPasswordTextField.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)
        emailTextField.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)

        let tapper = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tapper.cancelsTouchesInView = false
        view.addGestureRecognizer(tapper)


    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(observerRegistr)
    }

    @objc func textFieldDidChanged(_ textField : UITextField) {
        switch (textField) {
        case loginTextField:
            loginString = loginTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            loginValid = validateLogin(loginString)
            cellLogin.accessoryType = loginValid ? .checkmark : .none
        case passwordTextField:
            passwordString = passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            passwordValid = validatePassword(passwordString)
            cellPassword.accessoryType = passwordValid ? .checkmark : .none
        case repeatPasswordTextField:
            repeatPasswordValid = validatePasswordRepeat(repeatPasswordTextField.text!)
            cellRepeatPassword.accessoryType = repeatPasswordValid ? .checkmark : .none
        case emailTextField:
            emailString = emailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            emailValid = validateEmail(emailString)
            cellEmail.accessoryType = emailValid ? .checkmark : .none
        case inviteCodeTextField:
            inviteCodeString = inviteCodeTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        default: print("")
        }

        if loginValid && passwordValid && repeatPasswordValid && emailValid {
            NotificationCenter.default.post(name: NSNotification.Name("canRegistrTrue"), object: nil)
        } else {
            NotificationCenter.default.post(name: NSNotification.Name("canRegistrFalse"), object: nil)

        }
    }


    @IBAction func clickRegistrButton(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name("clickRegistrButton"), object: nil)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        switch (section) {
        case 0: return "Fill out the information".localized
        case 1: return ""
        default: return "Fill out the information".localized
        }
    }
}
