//
// Created by Vladislav on 22/10/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import UIKit
import Foundation
import QuartzCore

class YMWithdrawViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var errorLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var cryptoAmontTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var modalView: UIView!
    @IBOutlet weak var backgroundView: UIVisualEffectView!

    var ymBalance: Double?
    var accountAddress: String?
    var exchangeRate: Decimal?
    var localFormat: NumberFormatter!
    var charset: CharacterSet!
    var exchangeTimer: PMTimer!
    var exchangeIn:Decimal?, exchangeOut:Decimal?, minAmount:Int?, maxAmount:Int?
    var amount: Decimal = 0
    var amountWithFee: Decimal = 0
    var amountRubString = ""
    var amountCryptoString = ""

    @IBOutlet weak var titleLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()

        errorLabelHeight.constant = 0

        titleLabel.text = "Bitcoin wallet:".localized
        confirmButton.setTitle("WITHDRAW".localized, for: .normal)

        amountTextField.addTarget(self, action: #selector(amountRubChanged(_:)), for: .editingChanged)
        cryptoAmontTextField.addTarget(self, action: #selector(amountCryptoChanged(_:)), for: .editingChanged)

        confirmButton.layer.cornerRadius = 15;

        modalView.layer.cornerRadius = 14.0

        confirmButton.isEnabled = false
        errorLabel.isHidden = true

        let tapper = UITapGestureRecognizer(target: self, action: #selector(onCancelClicked))
        tapper.cancelsTouchesInView = false
        backgroundView.addGestureRecognizer(tapper)

        if User.ymAccessToken == nil {
            self.ymBalance = nil
        } else {
            TransactionManager.instance.getYMAccointInfo() { (balance, account) in
                if let balance = balance {
                    self.ymBalance = balance
                    if account != nil {
                        self.accountAddress = account
                    }

//                    DispatchQueue.main.async {
//                        self.balanceLabel.text = "₽ \(balance)"
//                    }
                }
            }
        }
        if let manager = BRWalletManager.sharedInstance() {
            if let balance:UInt64 = manager.wallet?.balance {
                balanceLabel.text = manager.string(forAmount: Int64(balance))
            } else {
                balanceLabel.text = "0.00 (no wallet)"
            }
        }

        localFormat = NumberFormatter()
        localFormat.isLenient = true
        localFormat.numberStyle = .currency
        localFormat.currencySymbol = "₽"
        localFormat.generatesDecimalNumbers = true
        localFormat.negativeFormat = localFormat.positiveFormat.replacingCharacters(in: localFormat.positiveFormat.range(of: "#")!, with: "-#")

        confirmButton.isEnabled = false

        charset = CharacterSet.decimalDigits
        charset.insert(charactersIn: localFormat.currencyDecimalSeparator!)

        amountTextField.delegate = self
        cryptoAmontTextField.delegate = self

        exchangeTimer = PMTimer(timeout: TimeInterval(10), repeat: true, completionFunction: {
            self.updateExchangeRate()
        }, queue: Queue().nativeQueue())
        updateExchangeRate()
    }

    @IBAction func onCancelClicked(_ sender: Any) {
        dismiss(animated: true)
    }

    func textField(_ textField: UITextField!, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let countdots = textField!.text!.components(separatedBy: ".").count - 1 //дома исправлю ошибку!

        if countdots > 0 && string == "." {
            return false
        }
        return true
    }

    @objc func amountRubChanged(_ rubTextField: UITextField) {
            amountRubString = rubTextField.text!

            if (amountRubString.contains(",")) {
                amountRubString = amountRubString.replacingOccurrences(of: ",", with: ".")
            }

            rubTextField.text! = amountRubString

        if exchangeIn != nil {
            if (!amountRubString.isEmpty && amountRubString != ".") {
                cryptoAmontTextField.text = "\(Decimal(string: amountRubString)! / exchangeIn!)"
            } else {
                cryptoAmontTextField.text = ""
            }
        }
    }

    func amountCryptoChanged(_ cryptoTextField: UITextField) {
        amountCryptoString = cryptoTextField.text!

        if (amountCryptoString.contains(",")) {
            amountCryptoString = amountCryptoString.replacingOccurrences(of: ",", with: ".")
        }

        cryptoTextField.text! = amountCryptoString

        if exchangeIn != nil {
            if (!amountCryptoString.isEmpty && amountCryptoString != ".") {
                amountTextField.text = "\(Decimal(string: amountCryptoString)! * exchangeIn!)"
            } else {
                amountTextField.text = ""
            }
        }
    }

    @IBAction func onEditChanged(_ sender: UITextField) {
        if let text = sender.text {
            if text.count > 0 {
                /*
                [[NSDecimalNumber decimalNumberWithDecimal:[self.format numberFromString:string].decimalValue]
             decimalNumberByMultiplyingByPowerOf10:self.format.maximumFractionDigits].longLongValue;
                */
                if let number = localFormat.number(from: text) {
                    let num = NSDecimalNumber(decimal: number.decimalValue)
                    print(num)
                }
                updateViews()
            } else {
                confirmButton.isEnabled = false
            }
        }
    }

    func updateExchangeRate() {
        TransactionManager.instance.exchangeRateTask(from: .RUR, to: .BTC) { (exchangeIn, exchangeOut, minAmount, maxAmount) in
            if exchangeIn != nil && exchangeOut != nil && minAmount != nil && maxAmount != nil {
                self.exchangeIn = exchangeIn
                self.exchangeOut = exchangeOut
                self.minAmount = minAmount
                self.maxAmount = maxAmount

//                print(exchangeOut!)
                print(exchangeIn!)
//                print(self.amountWithFee)

                self.updateViews()
            } else {
                DispatchQueue.main.async {
                    self.errorLabel.isHidden = false;
                    self.errorLabelHeight.constant = 17

                    self.errorLabel.text = "Failed to load exchange rate".localized
                    self.confirmButton.isEnabled = false
                }
            }
        }
    }

    func updateViews() {
        if let exchange = exchangeIn, let maxAmount = maxAmount, let minAmount = minAmount {
            if let manager = BRWalletManager.sharedInstance() {
                if let amount = localFormat.number(from: amountTextField.text!)?.decimalValue {
                    self.amount = amount

//                    print(amount)

                    self.errorLabel.isHidden = true;

                    let n = Int64(NSDecimalNumber(
                            decimal: (amount / exchange * Decimal(SATOSHIS)))
                            .rounding(accordingToBehavior: NSDecimalNumberHandler(roundingMode: .plain, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)))
//                    print(n)
//                    futureAmountLabel.text = "\(manager.string(forAmount: n))"
                    if ymBalance != nil && amount > Decimal(ymBalance!) {
                        errorLabel.isHidden = false
                        errorLabelHeight.constant = 17

                        errorLabel.text = "You don't have enough money".localized
                        confirmButton.isEnabled = false
                    } else if amount < Decimal(minAmount) || amount > Decimal(maxAmount) {
                        errorLabel.isHidden = false
                        errorLabelHeight.constant = 17

                        errorLabel.text = "Allowed amount: ".localized + "\(localFormat.currencySymbol!) \(minAmount)-\(maxAmount)"
                        confirmButton.isEnabled = false
                    } else {
                        errorLabelHeight.constant = 0

                        errorLabel.isHidden = true
                        confirmButton.isEnabled = true
                    }
                }
            }
        }

        if exchangeOut != nil && exchangeIn != nil && exchangeOut! != 0 && exchangeIn! != 0 {
            self.amountWithFee = (self.amount / exchangeOut!) / exchangeIn!;
        }
    }

    @IBAction func onDepositClicked(_ sender: Any) {
        if let address = BRWalletManager.sharedInstance()?.wallet?.receiveAddress, let accountAddress = self.accountAddress {
            TransactionManager.instance.doUniversalTask(TransactionManager.TransactionTaskInput(.BTC, .YANDEX_MONEY, amount, amountWithFee, accountAddress, address, 0, 0, 0)) { tto in
                print(tto?.status!)
            }
        } else {
            print("ERROR SENDING BTC->YDX")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        exchangeTimer.start()
    }

    override func viewDidDisappear(_ animated: Bool) {
        exchangeTimer.stop()
        super.viewDidDisappear(animated)
    }
}
