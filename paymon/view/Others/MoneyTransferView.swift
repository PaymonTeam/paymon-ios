//
// Created by Vladislav on 20/09/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import UIKit

class MoneyTransferView: UIViewController, UITextFieldDelegate, UIAlertViewDelegate {
    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var localCurrencyLabel: UILabel!
    @IBOutlet weak var payButton: UIButton!
    @IBOutlet weak var lock: UIBarButtonItem!
    @IBOutlet weak var delButton: UIButton!
    @IBOutlet weak var decimalButton: UIButton!

    var balanceObserver: NSObjectProtocol!
    var backgroundObserver: NSObjectProtocol!
    var amount: UInt64 = 0
    var charset: CharacterSet!
    var swapLeftLabel: UILabel!
    var swapRightLabel: UILabel!
    var swapped: Bool = false
//    id balanceObserver, backgroundObserver

    override func viewDidLoad() {
        super.viewDidLoad()
        if let manager = BRWalletManager.sharedInstance() {
            var charset = CharacterSet.decimalDigits
//        charset.addCharacters(in: manager.format.currencyDecimalSeparator)
            charset.insert(charactersIn: manager.format!.currencyDecimalSeparator!)
            self.charset = charset
//            payButton = UIButton(type: .system)
//            payButton.titleLabel?.text = "pay" //NSLocalizedString("pay", comment: "")
//            payButton.target(forAction: #selector(self.pay), withSender: self)
            amountField.placeholder = manager.string(forAmount: 0)
            decimalButton.setTitle(manager.format?.currencyDecimalSeparator, for: .normal)
            swapLeftLabel = UILabel()
            swapLeftLabel.font = localCurrencyLabel.font
            swapLeftLabel.alpha = localCurrencyLabel.alpha
            swapLeftLabel.textAlignment = localCurrencyLabel.textAlignment
            swapLeftLabel.isHidden = true
            swapRightLabel = UILabel()
            swapRightLabel.font = amountField.font
            swapRightLabel.alpha = amountField.alpha
            swapRightLabel.textAlignment = amountField.textAlignment
            swapRightLabel.isHidden = true
            updateLocalCurrencyLabel()
//            balanceObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.BRWalletBalanceChanged, object: nil, queue: nil, using: { (_ note: Notification) -> Void in
//                if BRPeerManager.sharedInstance()!.syncProgress < 1.0 {
//                    return
//                }
//                // wait for sync before updating balance
//                self.navigationItem.title = "\(manager.string(forAmount: Int64(manager.wallet!.balance))) (\(manager.localCurrencyString(forAmount: Int64(manager.wallet!.balance)))"
//            })
//            backgroundObserver = NotificationCenter.default.addObserver(forName: .UIApplicationDidEnterBackground, object: nil, queue: nil, using: { (_ note: Notification) -> Void in
////                self.navigationItem.titleView = self.logo
//            })
        }
    }

    func updateLocalCurrencyLabel() {
        if let manager = BRWalletManager.sharedInstance() {
            var amount: UInt64 = swapped ? UInt64(manager.amount(forLocalCurrencyString: amountField.text!)) : UInt64(manager.amount(for: amountField.text))
            swapLeftLabel.isHidden = true
            localCurrencyLabel.isHidden = false
            localCurrencyLabel.text = "(\(swapped ? manager.string(forAmount: Int64(amount)) : manager.localCurrencyString(forAmount: Int64(amount))))"
            localCurrencyLabel.textColor = (amount > 0) ? UIColor.gray : UIColor(white: 0.75, alpha: 1.0)
        }
    }

    @IBAction func unlock(_ sender: Any?) {
        if let manager = BRWalletManager.sharedInstance() {
//        BREventManager.saveEvent("amount:unlock")
            if sender != nil && !manager.didAuthenticate && !manager.authenticate(withPrompt: nil, andTouchId: true) {
                return
            }
//        BREventManager.saveEvent("amount:successful_unlock")
            navigationItem.titleView = nil
//            navigationItem.setRightBarButton(payButton, animated: sender ? true : false)
        }
    }

    @IBAction func number(_ sender: Any?) {
        var l: Int = amountField.text!.count//.rangeOfCharacter(from: charset, options: .backwards)!.upperBound.encodedOffset
//        l = (l < amountField.text!.count) ? l + 1 : amountField.text!.count
        _ = textField(amountField, shouldChangeCharactersIn: NSRange(location: l, length: 0), replacementString: (((sender as? UIButton)?.titleLabel)?.text)!)
    }

    @IBAction func del(_ sender: Any?) {
        var l: Int = amountField.text!.count - 1//rangeOfCharacter(from: charset, options: .backwards).location
        if l < amountField.text!.count {
            _ = textField(amountField, shouldChangeCharactersIn: NSRange(location: l, length: 1), replacementString: "")
        }
    }

    @IBAction func pay(_ sender: Any?) {
        if let manager = BRWalletManager.sharedInstance() {
            amount = swapped ? UInt64(manager.amount(forLocalCurrencyString: amountField.text!)) : UInt64(manager.amount(for: amountField.text!))
            if amount == 0 {
//            BREventManager.saveEvent("amount:pay_zero")
                return
            }
        }
//        BREventManager.saveEvent("amount:pay")
//        delegate.amountViewController(self, selectedAmount: amount)
    }

    @IBAction func done(_ sender: Any?) {
//        BREventManager.saveEvent("amount:dismiss")
        navigationController?.presentingViewController?.dismiss(animated: true) { _ in
        }
    }

    @IBAction func swapCurrency(_ sender: Any?) {
        self.swapped = !self.swapped;
//        BREventManager.saveEvent("amount:swap_currency")
        if swapLeftLabel.isHidden {
            swapLeftLabel.text = localCurrencyLabel.text
            swapLeftLabel.textColor = (amountField.text!.count > 0) ? amountField.textColor : UIColor(white: 0.75, alpha: 1.0)
            swapLeftLabel.frame = localCurrencyLabel.frame
            localCurrencyLabel.superview!.addSubview(swapLeftLabel)
            swapLeftLabel.isHidden = false
            localCurrencyLabel.isHidden = true
        }

        if swapRightLabel.isHidden {
            swapRightLabel.text = (amountField.text!.count > 0) ? amountField.text : amountField.placeholder
            swapRightLabel.textColor = (amountField.text!.count > 0) ? amountField.textColor : UIColor(white: 0.75, alpha: 1.0)
            swapRightLabel.frame = amountField.frame
            amountField.superview!.addSubview(swapRightLabel)
            swapRightLabel.isHidden = false
            amountField.isHidden = true
        }
        var scale: CGFloat = swapRightLabel.font.pointSize / swapLeftLabel.font.pointSize
        if let manager = BRWalletManager.sharedInstance() {
            var s: String = swapped ? localCurrencyLabel.text! : amountField.text!
            var amount: UInt64 = UInt64(manager.amount(forLocalCurrencyString: swapped ? (s as NSString).substring(with: NSRange(location: 1, length: (s.count ?? 0) - 2)) : s))
            localCurrencyLabel.text = "(\(swapped ? manager.string(forAmount: Int64(amount)) : manager.localCurrencyString(forAmount: Int64(amount))))"
            amountField.text = swapped ? manager.localCurrencyString(forAmount: Int64(amount)) : manager.string(forAmount: Int64(amount))
            if amount == 0 {
                amountField.placeholder = amountField.text
                amountField.text = nil
            } else {
                amountField.placeholder = nil
            }
            view.layoutIfNeeded()
            var p = CGPoint(x: localCurrencyLabel.frame.origin.x + localCurrencyLabel.bounds.size.width / 2.0 + amountField.bounds.size.width / 2.0, y: localCurrencyLabel.center.y / 2.0 + amountField.center.y / 2.0)
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: { () -> Void in
                self.swapLeftLabel.transform = CGAffineTransform(scaleX: scale / 0.85, y: scale / 0.85)
                self.swapRightLabel.transform = CGAffineTransform(scaleX: 0.85 / scale, y: 0.85 / scale)
            }) { _ in
            }
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseIn, animations: { () -> Void in
                self.swapRightLabel.center = p
                self.swapLeftLabel.center = self.swapRightLabel.center
            }, completion: { (_ finished: Bool) -> Void in
                self.swapLeftLabel.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                self.swapRightLabel.transform = CGAffineTransform(scaleX: 1.0 / 0.85, y: 1.0 / 0.85)
                self.swapLeftLabel.text = self.localCurrencyLabel.text
                self.swapRightLabel.text = (self.amountField.text!.count > 0) ? self.amountField.text : self.amountField.placeholder
                self.swapLeftLabel.textColor = self.localCurrencyLabel.textColor
                self.swapRightLabel.textColor = (self.amountField.text!.count > 0) ? self.amountField.textColor : UIColor(white: 0.75, alpha: 1.0)
                self.swapLeftLabel.sizeToFit()
                self.swapRightLabel.sizeToFit()
                self.swapRightLabel.center = p
                self.swapLeftLabel.center = self.swapRightLabel.center
                UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: .curveEaseIn, animations: { () -> Void in
                    self.swapLeftLabel.transform = CGAffineTransform.identity
                    self.swapRightLabel.transform = CGAffineTransform.identity
                }) { _ in
                }
                UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.0, options: .curveEaseOut, animations: { () -> Void in
                    self.swapLeftLabel.frame = self.localCurrencyLabel.frame
                    self.swapRightLabel.frame = self.amountField.frame
                }) { _ in
                }
            })
        }
    }

    @IBAction func pressSwapButton(_ sender: Any?) {
//        BREventManager.saveEvent("amount:press_swap")
        if swapLeftLabel.isHidden {
            swapLeftLabel.text = localCurrencyLabel.text
            swapLeftLabel.frame = localCurrencyLabel.frame
            localCurrencyLabel.superview!.addSubview(swapLeftLabel)
            swapLeftLabel.isHidden = false
            localCurrencyLabel.isHidden = true
        }
        swapLeftLabel.textColor = localCurrencyLabel.textColor
        if swapRightLabel.isHidden {
            swapRightLabel.text = (amountField.text!.count > 0) ? amountField.text : amountField.placeholder
            swapRightLabel.frame = amountField.frame
            amountField.superview!.addSubview(swapRightLabel)
            swapRightLabel.isHidden = false
            amountField.isHidden = true
        }
        swapRightLabel.textColor = (amountField.text!.count > 0) ? amountField.textColor : UIColor(white: 0.75, alpha: 1.0)
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            //self.swapLeftLabel.transform = CGAffineTransformMakeScale(0.85, 0.85);
            self.swapLeftLabel.textColor = self.swapRightLabel.textColor
            self.swapRightLabel.textColor = self.localCurrencyLabel.textColor
            self.swapLeftLabel.text = self.swapLeftLabel.text!.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
        })
    }

    @IBAction func releaseSwapButton(_ sender: Any?) {
//        BREventManager.saveEvent("amount:release_swap")
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            //self.swapLeftLabel.transform = CGAffineTransformIdentity;
            self.swapLeftLabel.textColor = self.localCurrencyLabel.textColor
        }, completion: { (_ finished: Bool) -> Void in
            self.swapRightLabel.isHidden = true
            self.swapLeftLabel.isHidden = self.swapRightLabel.isHidden
            self.amountField.isHidden = false
            self.localCurrencyLabel.isHidden = self.amountField.isHidden
        })
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn nsrange: NSRange, replacementString string: String) -> Bool {
        if let manager = BRWalletManager.sharedInstance() {
            var numberFormatter: NumberFormatter! = swapped ? manager.localFormat : manager.format
            let decimalLoc: Int
            if let range1 = textField.text!.range(of: numberFormatter.currencyDecimalSeparator) {
                decimalLoc = textField.text!.nsRange(fromRange: range1).location //range1?.lowerBound.encodedOffset
            } else {
                decimalLoc = NSNotFound
            }
            let range2: Range! = textField.text!.range(fromRange: nsrange)

            var minimumFractionDigits: Int! = numberFormatter.minimumFractionDigits
            var textVal: String! = textField.text!
            var zeroStr: String! = nil
            var num: NSDecimalNumber!
            if textVal == "" {
                textVal = ""
            }
            numberFormatter?.minimumFractionDigits = 0
            zeroStr = numberFormatter?.string(from: 0)
            // if amount is prefixed with currency symbol, then equivalent to [zeroStr stringByAppendingString:numberFormatter.currencyDecimalSeparator]
            // otherwise, numberFormatter.currencyDecimalSeparator must be inserted exactly after 0
            var zeroStrByInsertingCurrencyDecimalSeparator: (() -> String)? = { () -> String in
                var zeroCharacterRange: NSRange! = (zeroStr as NSString?)?.rangeOfCharacter(from: self.charset)
                return (zeroStr as NSString?)?.replacingCharacters(in: NSRange(location: NSMaxRange(zeroCharacterRange), length: 0), with: numberFormatter.currencyDecimalSeparator) ?? ""
            }

            if string.count == 0 {
                // delete button
                textVal = textVal.replacingCharacters(in: range2, with: string)
                if nsrange.location <= decimalLoc {
                    // deleting before the decimal requires reformatting
                    textVal = numberFormatter.string(from: numberFormatter.number(from: textVal) ?? 0)
                }
                if !(textVal != nil || textVal.isEqual(zeroStr)) {
                    textVal = ""
                }
                // check if we are left with a zero amount
            } else if string.isEqual(numberFormatter.currencyDecimalSeparator) {
                // decimal point button
                if decimalLoc == NSNotFound && numberFormatter.maximumFractionDigits > 0 {
                    textVal = (textVal.count == 0) ? zeroStrByInsertingCurrencyDecimalSeparator?() : textVal.replacingCharacters(in: range2, with: string)
                }
            } else {
                // digit button
                // check for too many digits after the decimal point
                if nsrange.location > decimalLoc && nsrange.location - decimalLoc > numberFormatter.maximumFractionDigits {
                    numberFormatter.minimumFractionDigits = numberFormatter.maximumFractionDigits
                    num = NSDecimalNumber(decimal: (numberFormatter.number(from: textVal)?.decimalValue)!)
                    num = num.multiplying(byPowerOf10: 1)
                    num = num.adding(NSDecimalNumber(string: string).multiplying(byPowerOf10: Int16(-numberFormatter.maximumFractionDigits)))
                    textVal = numberFormatter.string(from: num)!
                    if numberFormatter.number(from: textVal) == nil {
                        textVal = nil
                    } else if textVal.count == 0 && string.isEqual("0") {
                    }
                    // if first digit is zero, append decimal point
                    textVal = zeroStrByInsertingCurrencyDecimalSeparator?()
                } else if nsrange.location > decimalLoc && string.isEqual("0") {
                    // handle multiple zeros after decimal point
                    textVal = textVal.replacingCharacters(in: range2, with: string)
                } else {
                    if let number1 = numberFormatter.number(from: textVal.replacingCharacters(in: range2, with: string)) {
                        textVal = numberFormatter.string(from: number1)
                    }
                }
            }

            if textVal != nil {
                textField.text = textVal
            }
            numberFormatter.minimumFractionDigits = minimumFractionDigits
            if textVal != nil && textVal.count > 0 && textField.placeholder != nil && textField.placeholder!.count > 0 {
                textField.placeholder = nil
            }
            if textVal != nil && textVal.count == 0 && textField.placeholder != nil && textField.placeholder!.count == 0 {
                textField.placeholder = swapped ? manager.localCurrencyString(forAmount: 0) : manager.string(forAmount: 0)
            }
            if navigationController?.viewControllers.first != self {
                if !(manager.didAuthenticate && textVal != nil && textVal.count == 0 && navigationItem.rightBarButtonItem != lock) {
                    navigationItem.setRightBarButton(lock, animated: true)
                } else if textVal != nil && textVal.count > 0 && navigationItem.rightBarButtonItem != payButton {
//                    navigationItem.setRightBarButton(payButton, animated: true)
                }
            }
            swapRightLabel.isHidden = true
            textField.isHidden = false
            updateLocalCurrencyLabel()
            return false
        }
        return false
    }
}
