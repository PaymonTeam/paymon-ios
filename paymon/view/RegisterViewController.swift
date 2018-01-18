//
// Created by Vladislav on 28/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import UIKit
import Foundation

class RegisterViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var tableViewDoneRegister: UITableView!
    @IBOutlet weak var loginButton: UIButton!

    var tableViewDoneRegisterDataSource: TableViewDoneRegisterDataSource!
    var tableViewDoneRegisterDelegate: TableViewDoneRegisterDelegate!

    let list = ["Login".localized, "Password".localized, "Repeat".localized, "E-mail".localized, "Invite code".localized]
    let hintsList = ["At least 3 symbols".localized, "At least 8 symbols".localized, "Required".localized, "Required".localized, "Optional".localized]
    var imageCross: UIImage!
    var imageChecked: UIImage!
    let borderColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)
    var passwordString:String!
    var passwordValidated:Bool = false

    @IBAction func onLoginClicked() {
        dismiss(animated: true)
    }

    @IBAction func onRegisterClicked() {

    }

    @IBAction func onTapOutside() {
        for i in 0..<list.count {
            let index = IndexPath(row: i, section: 0)
            (tableView.cellForRow(at: index) as? TextFieldWithImageInTableViewCell)?.textField.endEditing(true)
        }
    }

    @IBAction private func onNavBarItemLeftClicked() {
        dismiss(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let navigationItem = UINavigationItem()

        let leftButton = UIBarButtonItem(image: UIImage(named: "nav_bar_item_arrow_left"), style: .plain, target: self, action: #selector(onNavBarItemLeftClicked))

        navigationItem.leftBarButtonItem = leftButton

        navigationItem.title = "Registration".localized

        navigationBar.items = [navigationItem]

        imageCross = UIImage(named: "cross.png")
        imageChecked = UIImage(named: "checked.png")

        tableViewDoneRegisterDataSource = TableViewDoneRegisterDataSource()
        tableViewDoneRegisterDelegate = TableViewDoneRegisterDelegate(controller: self)

        setupTableView()
        loginButton.setTitle("I already have an account".localized, for: .normal)
        loginButton.addTarget(self, action: #selector(onLoginClicked), for: .touchUpInside)

        let tapper = UITapGestureRecognizer(target: self, action:#selector(onTapOutside))
        tapper.cancelsTouchesInView = false
        view.addGestureRecognizer(tapper)
    }

    override func viewDidAppear(_ animated: Bool) {
        tableView.sizeToFit()
//        tableView.addBorderTop(size: 1.0, color: borderColor)
//        tableView.addBorderBottom(size: 1.0, color: borderColor)

        tableViewDoneRegister.sizeToFit()
//        tableViewDoneRegister.addBorderTop(size: 1.0, color: borderColor)
//        tableViewDoneRegister.addBorderBottom(size: 1.0, color: borderColor)
    }

    func validateLogin(_ newText:String) -> Bool {
        if newText.utf8.count < 3 { return false }

        let regexStr = "^[a-zA-Z0-9-_\\.]+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regexStr)
        return predicate.evaluate(with: newText)
    }

    func validatePassword(_ newText:String) -> Bool {
        let matched = newText.utf8.count >= 8
        passwordString = newText
        passwordValidated = matched
        return matched
    }

    func validatePasswordRepeat(_ newText:String) -> Bool {
        return passwordValidated && (newText == passwordString)
    }

    func validateEmail(_ newText:String) -> Bool {
        let regexStr = ".+@.+\\..+"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regexStr)
        return predicate.evaluate(with: newText)
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        var i = 0
        for var hint in hintsList {
            if i == hintsList.count - 1 {
                (tableView.cellForRow(at: IndexPath(row: i, section: 0)) as? TextFieldWithImageInTableViewCell)?.textField?.endEditing(true)
            } else {
                if textField.placeholder == hint {
                    (tableView.cellForRow(at: IndexPath(row: i + 1, section: 0)) as? TextFieldWithImageInTableViewCell)?.textField?.becomeFirstResponder()
                }
            }
            i += 1
        }
        return true
    }
}


// MARK: - tableViewDoneRegister

class TableViewDoneRegisterDataSource : NSObject, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "tableViewDoneRegister")// as! UITableViewCell
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "tableViewDoneRegister")
            cell!.textLabel!.text = "Register".localized
        }
        return cell!
    }
}

class TableViewDoneRegisterDelegate : NSObject, UITableViewDelegate {
    weak var controller: RegisterViewController!
    var indicator:UIActivityIndicatorView!

    init(controller: RegisterViewController!) {
        self.controller = controller
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if let loginCell = (controller.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TextFieldWithImageInTableViewCell) {
            let passwordCell = (controller.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as! TextFieldWithImageInTableViewCell)
            let repeatPasswordCell = (controller.tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as! TextFieldWithImageInTableViewCell)
            let emailCell = (controller.tableView.cellForRow(at: IndexPath(row: 3, section: 0)) as! TextFieldWithImageInTableViewCell)
            let inviteCodeCell = (controller.tableView.cellForRow(at: IndexPath(row: 4, section: 0)) as! TextFieldWithImageInTableViewCell)

            let loginString = loginCell.textField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let passwordString = passwordCell.textField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let passwordRepeatString = repeatPasswordCell.textField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let emailString = emailCell.textField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let inviteCodeString = inviteCodeCell.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)

            if !controller.validateLogin(loginString) {
                loginCell.shake()
                return
            }

            if !controller.validatePassword(passwordString) {
                passwordCell.shake()
                return
            }

            if !controller.validatePasswordRepeat(passwordRepeatString) {
                repeatPasswordCell.shake()
                return
            }

            if !controller.validateEmail(emailString) {
                emailCell.shake()
                return
            }

            indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
            indicator.frame = CGRect(x: 0.0, y: 0.0, width: 64.0, height: 64.0)
            indicator.center = controller.view.center
            controller.view.addSubview(indicator)
            indicator.bringSubview(toFront: controller.view)
//        UIApplication.shared.isNetworkActivityIndicatorVisible = true;
            indicator.startAnimating()

            let register = RPC.PM_register()
            register.login = loginString
            register.password = passwordString
            register.email = emailString
            register.walletKey = "OoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOo";
            register.inviteCode = inviteCodeString ?? "";

            let _ = NetworkManager.instance.sendPacket(register) { p,e in
                DispatchQueue.main.async {
                    self.indicator.stopAnimating()
                    tableView.deselectRow(at: indexPath, animated: true)
                }

                if let user = p as? RPC.PM_userFull {
                    print("User has logged in")
                    User.currentUser = user
                    User.isAuthenticated = true
                    User.saveConfig()
                    DispatchQueue.main.async {
                        self.controller.view.window!.rootViewController?.dismiss(animated: true, completion: nil)
                        NotificationManager.instance.postNotificationName(id: NotificationManager.userDidLoggedIn)
                    }
                } else if e != nil {
                    let alert = UIAlertController(title: "Registration Failed", message: e!.message, preferredStyle: UIAlertControllerStyle.alert)
                    let alertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
                        (UIAlertAction) -> Void in
                    }
                    alert.addAction(alertAction)
                    DispatchQueue.main.async {
                        self.controller.present(alert, animated: true) {
                            () -> Void in
                        }
                    }
                }
            }
        } else {
            print("NIL")
        }
    }
}

// MARK: - TableView

extension RegisterViewController {
    func setupTableView() {

//        tableViewLogin.delegate = tableViewLoginDelegate
//        tableViewLogin.dataSource = tableViewLoginDataSource
//        tableViewLogin.tableFooterView = UIView()
//
        tableViewDoneRegister.delegate = tableViewDoneRegisterDelegate
        tableViewDoneRegister.dataSource = tableViewDoneRegisterDataSource
        tableViewDoneRegister.tableFooterView = UIView()

        tableView.dataSource = self
        tableView.tableFooterView = UIView()

        let gesture = UITapGestureRecognizer(target: self, action: #selector(RegisterViewController.endEditing))
        tableView.addGestureRecognizer(gesture)

    }

    @objc func endEditing() {
        tableView.endEditing(true)
    }

}

// MARK: - UITableViewDataSource

extension RegisterViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldWithImageInTableViewCell") as! TextFieldWithImageInTableViewCell
        cell.delegate = self
        let row = indexPath.row
        cell.descriptionLabel.text = list[row]
        cell.textField.placeholder = hintsList[row]
        cell.textField.delegate = self
//        cell.hintImage = UIImageView(image: image)
        cell.hintImage.image = UIImage(named: "cross.png")
        cell.hintImage.isHidden = true

//        cell.hintImage.image = nil
        if list[row] == "Password" || list[row] == "Repeat" {
            cell.textField.isSecureTextEntry = true
            cell.maxLength = 64
        } else if list[row] == "Login" {
            cell.maxLength = 20
        } else if list[row] == "Invite code" {
            cell.maxLength = 10
        }
        return cell
    }
}

// MARK: - TextFieldWithImageInTableViewCellDelegate

extension RegisterViewController: TextFieldWithImageInTableViewCellDelegate {
    func textFieldInTableViewCell(didSelect cell:TextFieldWithImageInTableViewCell) {
        if tableView.indexPath(for: cell) != nil{
//            print("didSelect cell: \(indexPath)")
        }
    }

    func textFieldInTableViewCell(cell:TextFieldWithImageInTableViewCell, editingChangedInTextField newText:String) {
        if let indexPath = tableView.indexPath(for: cell) {
//            print("editingChangedInTextField: \"\(newText)\" in cell: \(indexPath)")
//            let cellName = list[indexPath.row]
//            let empty = newText.isEmpty
//            if !empty {
//                switch cellName {
//                case "Login":
//                    let matched = validateLogin(newText)
//                    cell.hintImage.image = (matched ? imageChecked : imageCross)
//                case "Password":
//                    let matched = validatePassword(newText)
//                    cell.hintImage.image = (matched ? imageChecked : imageCross)
//                    let repeatPasswordCell = (tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as! TextFieldWithImageInTableViewCell)
//                    if !repeatPasswordCell.textField.text!.isEmpty {
//                        let matched = validatePasswordRepeat(repeatPasswordCell.textField.text!)
//                        repeatPasswordCell.hintImage.image = (matched ? imageChecked : imageCross)
//                    }
//                case "Repeat":
//                    let matched = validatePasswordRepeat(newText)
//                    cell.hintImage.image = (matched ? imageChecked : imageCross)
//                case "E-mail":
//                    let matched = validateEmail(newText)
//                    cell.hintImage.image = (matched ? imageChecked : imageCross)
//                case "Invite code":
//                    cell.hintImage.image = nil
//                default:
//                    cell.hintImage.image = imageCross
//                }
//                //tableView.reloadData()
//                cell.reloadInputViews()
//                tableView.reloadInputViews()
//            }
//            cell.hintImage.isHidden = empty
        }
    }
    
}
