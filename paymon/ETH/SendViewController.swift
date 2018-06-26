//
//  SendViewController.swift
//  paymon
//
//  Created by Jogendar Singh on 24/06/18.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import Foundation

class SendViewController: UIViewController {
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var gasLimitTextField: UITextField!
    @IBOutlet weak var scanQRButton: UIButton!
    @IBOutlet weak var currencyButton: UIButton!
    @IBOutlet weak var gasPriceLabel: UILabel!
    @IBOutlet weak var localAmountLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var localFeeLabel: UILabel!
    @IBOutlet weak var feeLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var keyboardConstraint: NSLayoutConstraint!

//    var output: SendViewOutput!


    // MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
//        output.viewIsReady()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupKeyboardNotifications()
        amountTextField.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // MARK: Privates

    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
    }

    @objc func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo!
        let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue

        keyboardConstraint.constant = keyboardFrame.size.height + 10
        view.layoutIfNeeded()
    }

    @objc func keyboardWillHide(notification: Notification){
        keyboardConstraint.constant = 10
        view.layoutIfNeeded()
    }

    // MARK: Actions

    @IBAction func sendPressed(_ sender: UIButton) {

    }

    @IBAction func currencyPressed(_ sender: UIButton) {

    }

    @IBAction func scanQRPressed(_ sender: UIButton) {

    }

    @IBAction func addressDidChange(_ sender: UITextField) {

    }

    @IBAction func amountDidChange(_ sender: UITextField) {

    }

    @IBAction func gasLimitDidChange(_ sender: UITextField) {

    }

}

