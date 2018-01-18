//
//  SecurityPasswordViewController.swift
//  paymon
//
//  Created by maks on 10.10.17.
//  Copyright © 2017 Paymon. All rights reserved.
//

import UIKit

class SecurityPasswordViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var navigationBar: UINavigationBar!

    @IBOutlet weak var hintLabel: UILabel!
    @IBAction private func onNavBarItemLeftClicked() {
        dismiss(animated: true)
    }

    func onNavBarItemRightClicked () {
        User.securityPasswordProtectedString = passwordTextField.text!
        User.saveSecuritySettings()

        self.dismiss(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        hintLabel.text = "Enter your secret password".localized

        self.passwordTextField.delegate = self

        updateNavigationBar(visibleRight: false)

        if !User.securityPasswordProtectedString.isEmpty {
            passwordTextField.text = User.securityPasswordProtectedString
        }

        passwordTextField.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)

    }

    func updateNavigationBar(visibleRight : Bool){

        let navigationItem = UINavigationItem()

        let leftButton = UIBarButtonItem(image: UIImage(named: "nav_bar_item_arrow_left"), style: .plain, target: self, action: #selector(onNavBarItemLeftClicked))
        let rightButton = UIBarButtonItem(image: UIImage(named: "check"), style: .plain, target: self, action: #selector(onNavBarItemRightClicked))


        navigationItem.leftBarButtonItem = leftButton

        navigationItem.title = "Security password".localized

        if (!visibleRight) {
            navigationItem.rightBarButtonItem = nil
        } else {
            navigationItem.rightBarButtonItem = rightButton
        }

        navigationBar.items = [navigationItem]
    }

    @objc func textFieldDidChanged(_ textField : UITextField) {
        if !(passwordTextField.text?.isEmpty)! {
            updateNavigationBar(visibleRight: true)
        } else {
            updateNavigationBar(visibleRight: false)
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        let allowCharacters = CharacterSet.decimalDigits
        let characterSet = CharacterSet(charactersIn: string)
        return allowCharacters.isSuperset(of: characterSet)

    }
}
