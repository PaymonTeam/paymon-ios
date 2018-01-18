//
// Created by Vladislav on 22/10/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import UIKit
import Foundation
import QuartzCore

class YMDepositViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var errorLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var cryptoAmontTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var depositButton: UIButton!
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

        titleLabel.text = "Yandex wallet:".localized
        depositButton.setTitle("DEPOSIT".localized, for: .normal)

        amountTextField.addTarget(self, action: #selector(amountRubChanged(_:)), for: .editingChanged)
        cryptoAmontTextField.addTarget(self, action: #selector(amountCryptoChanged(_:)), for: .editingChanged)

        depositButton.layer.cornerRadius = 15;

        modalView.layer.cornerRadius = 14.0

        depositButton.isEnabled = false
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

                    DispatchQueue.main.async {
                        self.balanceLabel.text = "₽ \(balance)"
                    }
                }
            }
        }
        localFormat = NumberFormatter()
        localFormat.isLenient = true
        localFormat.numberStyle = .currency
        localFormat.currencySymbol = "₽"
        localFormat.generatesDecimalNumbers = true
        localFormat.negativeFormat = localFormat.positiveFormat.replacingCharacters(in: localFormat.positiveFormat.range(of: "#")!, with: "-#")

        depositButton.isEnabled = false

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
//                    print(num)
                }
                updateViews()
            } else {
                depositButton.isEnabled = false
            }
        }
    }

//    func amount(rubCurrencyString: String) -> Int64 {
//        var string = rubCurrencyString
//        if string.hasPrefix("<") {
//            string = (string as? NSString)?.substring(from: 1) ?? ""
//        }
//        let n = localFormat.number(from: string)
//        let price: Int64 = NSDecimalNumber(decimal: localPrice.decimalValue).multiplying(byPowerOf10: localFormat.maximumFractionDigits)
//        var local: Int64 = NSDecimalNumber(decimal: (n?.decimalValue)!).multiplying(byPowerOf10: localFormat.maximumFractionDigits)
//        var overflowbits: Int64 = 0
//        var p: Int64 = 10
//        var min: Int64
//        var max: Int64
//        var amount: Int64
//        if local == 0 || price < 1 {
//            return 0
//        }
//        while llabs(local) + 1 > INT64_MAX / SATOSHIS {
//            local /= 2
//            overflowbits += 1
//        }
//        min = llabs(local) * SATOSHIS / price + 1
//        max = (llabs(local) + 1) * SATOSHIS / price - 1
//        amount = (min + max) / 2
//        while overflowbits > 0 {
//            local *= 2
//            min *= 2
//            max *= 2
//            amount *= 2
//            overflowbits -= 1
//        }
//        if amount >= MAX_MONEY {
//            return (local < 0) ? -MAX_MONEY : MAX_MONEY
//        }
//        while (amount / p) * p >= min && p <= INT64_MAX / 10 {
//            p *= 10
//        }
//        // lowest decimal precision matching local currency string
//        p /= 10
//        return (local < 0) ? -(amount / p) * p : (amount / p) * p
//    }

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
                    self.depositButton.isEnabled = false
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
                        depositButton.isEnabled = false
                    } else if amount < Decimal(minAmount) || amount > Decimal(maxAmount) {
                        errorLabel.isHidden = false
                        errorLabelHeight.constant = 17

                        errorLabel.text = "Allowed amount: ".localized + "\(localFormat.currencySymbol!) \(minAmount)-\(maxAmount)"
                        depositButton.isEnabled = false
                    } else {
                        errorLabelHeight.constant = 0

                        errorLabel.isHidden = true
                        depositButton.isEnabled = true
                    }
                }
            }
//            let amount: UInt64 = UInt64(manager.amount(forLocalCurrencyString: amountTextField.text!)) //swapped ? UInt64(manager.amount(forLocalCurrencyString: amountField.text!)) : UInt64(manager.amount(for: amountField.text))
//            futureAmountLabel.text = "\(manager.string(forAmount: Int64(amount)))"
        }

        if exchangeOut != nil && exchangeIn != nil && exchangeOut! != 0 && exchangeIn! != 0 {
            self.amountWithFee = (self.amount / exchangeOut!) / exchangeIn!;
//            print("FEE \(amountWithFee)")
        }
    }

//    func textField(_ textField: UITextField, shouldChangeCharactersIn nsrange: NSRange, replacementString string: String) -> Bool {
//        let numberFormatter: NumberFormatter! = localFormat
//        let decimalLoc: Int
//        if let range1 = textField.text!.range(of: numberFormatter.currencyDecimalSeparator) {
//            decimalLoc = textField.text!.nsRange(fromRange: range1).location //range1?.lowerBound.encodedOffset
//        } else {
//            decimalLoc = NSNotFound
//        }
//        let range2: Range! = textField.text!.range(fromRange: nsrange)
//
//        let minimumFractionDigits: Int! = numberFormatter.minimumFractionDigits
//        var textVal: String! = textField.text!
//        var zeroStr: String! = nil
//        var num: NSDecimalNumber!
//        if textVal == nil {
//            textVal = ""
//        }
//        numberFormatter.minimumFractionDigits = 0
//        zeroStr = numberFormatter.string(from: 0)
//        // if amount is prefixed with currency symbol, then equivalent to [zeroStr stringByAppendingString:numberFormatter.currencyDecimalSeparator]
//        // otherwise, numberFormatter.currencyDecimalSeparator must be inserted exactly after 0
//        let zeroStrByInsertingCurrencyDecimalSeparator: (() -> String?) = { () -> String? in
//            let zeroCharacterRange: NSRange! = (zeroStr as NSString?)?.rangeOfCharacter(from: self.charset)
////            self.updateViews()
//            return (zeroStr as NSString?)?.replacingCharacters(in: NSRange(location: NSMaxRange(zeroCharacterRange), length: 0), with: numberFormatter.currencyDecimalSeparator) ?? nil
//        }
//
//        if string.count == 0 {
//            // delete button
//            textVal = textVal.replacingCharacters(in: range2, with: string)
//            if nsrange.location <= decimalLoc {
//                // deleting before the decimal requires reformatting
//                textVal = numberFormatter.string(from: numberFormatter.number(from: textVal) ?? 0)
//            }
//            if !(textVal != nil || textVal.isEqual(zeroStr)) {
//                textVal = ""
//            }
//            // check if we are left with a zero amount
//        } else if string.isEqual(numberFormatter.currencyDecimalSeparator) {
//            // decimal point button
//            if decimalLoc == NSNotFound && numberFormatter.maximumFractionDigits > 0 {
//                textVal = (textVal.count == 0) ? zeroStrByInsertingCurrencyDecimalSeparator() : textVal.replacingCharacters(in: range2, with: string)
//            }
//        } else {
//            // digit button
//            // check for too many digits after the decimal point
//            if nsrange.location > decimalLoc && nsrange.location - decimalLoc > numberFormatter.maximumFractionDigits {
//                numberFormatter.minimumFractionDigits = numberFormatter.maximumFractionDigits
//                num = NSDecimalNumber(decimal: (numberFormatter.number(from: textVal)?.decimalValue)!)
//                num = num.multiplying(byPowerOf10: 1)
//                num = num.adding(NSDecimalNumber(string: string).multiplying(byPowerOf10: Int16(-numberFormatter.maximumFractionDigits)))
//                textVal = numberFormatter.string(from: num)!
//                if numberFormatter.number(from: textVal) == nil {
//                    textVal = nil
//                } else if textVal.count == 0 && string.isEqual("0") {
//                }
////                if let separator = zeroStrByInsertingCurrencyDecimalSeparator() {
////                    textVal = separator
////                } else {
////                updateViews()
//                return false
////                }
//            } else if nsrange.location > decimalLoc && string.isEqual("0") {
//                // handle multiple zeros after decimal point
//                textVal = textVal.replacingCharacters(in: range2, with: string)
//            } else {
//                if let number1 = numberFormatter.number(from: textVal.replacingCharacters(in: range2, with: string)) {
//                    textVal = numberFormatter.string(from: number1)
//                }
//            }
//        }
//
//        if textVal != nil {
//            textField.text = textVal
//        }
//        numberFormatter.minimumFractionDigits = minimumFractionDigits
//        if textVal != nil && textVal.count > 0 && textField.placeholder != nil && textField.placeholder!.count > 0 {
//            textField.placeholder = nil
//        }
//        if textVal != nil && textVal.count == 0 && textField.placeholder != nil && textField.placeholder!.count == 0 {
//            textField.placeholder = "0.00"
//        }
//        textField.isHidden = false
//
////        updateViews()
//
//        return false
//    }

    @IBAction func onDepositClicked(_ sender: Any) {
        if let address = BRWalletManager.sharedInstance()?.wallet?.receiveAddress, let accountAddress = self.accountAddress {
            TransactionManager.instance.doUniversalTask(TransactionManager.TransactionTaskInput(.YANDEX_MONEY, .BTC, amount, amountWithFee, accountAddress, address, 0, 0, 0)) { tto in
                print(tto?.status!)
            }
        } else {
            print("ERROR SENDING YDX->BTC")
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
