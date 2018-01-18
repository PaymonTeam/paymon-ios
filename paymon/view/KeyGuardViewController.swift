//
//  KeyGuardViewController.swift
//  paymon
//
//  Created by maks on 09.10.17.
//  Copyright © 2017 Paymon. All rights reserved.
//

import UIKit

class KeyGuardViewController: UIViewController {

    var passwordString = ""

    
    @IBOutlet weak var hintLabel: UILabel!
    @IBOutlet weak var unlockButton: UIButton!
    @IBOutlet weak var eraseButton: UIButton!
    @IBOutlet weak var oneButton: UIButton!
    @IBOutlet weak var twoButton: UIButton!
    @IBOutlet weak var threeButton: UIButton!
    @IBOutlet weak var fourButton: UIButton!
    @IBOutlet weak var fiveButton: UIButton!
    @IBOutlet weak var sixButton: UIButton!
    @IBOutlet weak var sevenButton: UIButton!
    @IBOutlet weak var eightButton: UIButton!
    @IBOutlet weak var nineButton: UIButton!
    @IBOutlet weak var nullButton: UIButton!
    @IBOutlet weak var passwordTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        hintLabel.text="Input your password".localized

        self.view.addBackground()

        passwordTextField.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .touchUpOutside)

        passwordTextField.isEnabled = false

    }

    @IBAction func unlockButtonClick(_ sender: Any) {

        passwordString = passwordTextField.text!

        print(passwordString)
        print(User.securityPasswordProtectedString)

        if passwordString == User.securityPasswordProtectedString {

            let tabBar = storyboard?.instantiateViewController(withIdentifier: "TabsView") as! TabsViewController
//            tabBar.selectedIndex = 1
            present(tabBar, animated: true)

        }

    }

    @objc func textFieldDidChanged(_ textField : UITextField) {

    }


    @IBAction func eraseButtonClick(_ sender: Any) {

        passwordString = passwordTextField.text!

        passwordString = String(passwordString.dropLast())

        passwordTextField.text! = passwordString

    }


    @IBAction func oneButtonClick(_ sender: Any) {

//        passwordString.append("1")
//        passwordTextField.text = passwordString
        passwordTextField.text!.append("1")

    }

    @IBAction func twoButtonClick(_ sender: Any) {

        passwordTextField.text!.append("2")


    }

    @IBAction func threeButtonClick(_ sender: Any) {

        passwordTextField.text!.append("3")

    }

    @IBAction func fourButtonClick(_ sender: Any) {

        passwordTextField.text!.append("4")


    }

    @IBAction func fiveButtonClick(_ sender: Any) {

        passwordTextField.text!.append("5")


    }

    @IBAction func sixButtonClick(_ sender: Any) {

        passwordTextField.text!.append("6")


    }

    @IBAction func sevenButtonClick(_ sender: Any) {

        passwordTextField.text!.append("7")


    }

    @IBAction func eightButtonClick(_ sender: Any) {

        passwordTextField.text!.append("8")


    }

    @IBAction func nineButtonClick(_ sender: Any) {

        passwordTextField.text!.append("9")


    }

    @IBAction func nullButtonClick(_ sender: Any) {

        passwordTextField.text!.append("0")


    }

}
