//
// Created by maks on 22.10.17.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import UIKit

class BitcoinAddressInfoViewController: UIViewController {
    @IBOutlet weak var hintTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var qrImage: UIImageView!
    @IBOutlet weak var hintLabel: UILabel!
    @IBOutlet weak var modalView: UIView!
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var backgroundView: UIVisualEffectView!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        modalView.layer.cornerRadius = 14.0

        let tapper = UITapGestureRecognizer(target: self, action: #selector(onCancelClicked))
        tapper.cancelsTouchesInView = false
        backgroundView.addGestureRecognizer(tapper)

        let tapQrCode = UITapGestureRecognizer(target: self, action: #selector(BitcoinAddressInfoViewController.startShareActivity(_:)))
        qrImage.isUserInteractionEnabled = true
        qrImage.addGestureRecognizer(tapQrCode)

        if let manager = BRWalletManager.sharedInstance() {

            if Config.QR_CODE_ADDRESS.isEmpty {
                hintLabel.text = "This is address of your Bitcoin wallet. To send to someone, click on QR code.".localized
                codeLabel.text = String(manager.wallet!.receiveAddress!)
                hintTopConstraint.constant = 8
            } else {
                hintLabel.text = "Address of the recipient".localized
                codeLabel.text = String(Config.QR_CODE_ADDRESS)
                hintTopConstraint.constant = 24

            }
//            self.addressButton.titleLabel!.text = manager.wallet!.receiveAddress!;
//            self.addressButton.setTitle(manager.wallet!.receiveAddress!, for: .normal)
            if let groupDefs = UserDefaults(suiteName: "group.org.voisine.breadwallet") {
                var image: UIImage!
                if let req = BRPaymentRequest(string: codeLabel.text) {
                    if let data = groupDefs.object(forKey: "kBRSharedContainerDataWalletQRImageKey") as? Data {
                        if req.isValid {
                            qrImage.image = UIImage(data: data)!.resize(qrImage.bounds.size, with: .none)
                        }
                    }

                    if let data = groupDefs.object(forKey: "kBRSharedContainerDataWalletRequestDataKey") as? Data {
                        if req.data == data {
                            image = UIImage(data: data)
                        }
                    }

                    if image == nil && req.data != nil {
                        if let imgData = req.data {
                            image = UIImage(qrCodeData: imgData, color: CIColor(red: 0.0, green: 0.0, blue: 0.0))
                        }

                    }

                    if image != nil {
                        qrImage.image = image.resize(qrImage.bounds.size, with: .none)
                    }
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        Config.QR_CODE_ADDRESS = ""
    }

    func startShareActivity(_ sender: AnyObject) {

        let shareActivity = UIActivityViewController(activityItems: [codeLabel.text!], applicationActivities: [])

        shareActivity.popoverPresentationController?.sourceView = self.view
        shareActivity.popoverPresentationController?.sourceRect = self.view.bounds

        present(shareActivity, animated: true)
    }

    @IBAction func onCancelClicked(_ sender: Any) {
        dismiss(animated: true)
    }

    @IBAction func onAddressButtonClicked(_ sender: Any) {

    }
}

class NewMoneyTransferView: UIViewController {

    @IBOutlet weak var crossButton: UIImageView!

    @IBOutlet weak var hintLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var viewWalletHeight: NSLayoutConstraint!

    @IBOutlet weak var minAmountHint: UILabel!
    @IBOutlet weak var keyButton: UIImageView!
    @IBOutlet weak var addressTextField: UITextField!

    @IBOutlet weak var amountCryptoTextField: UITextField!
    @IBOutlet weak var amountRubTextField: UITextField!
    @IBOutlet weak var viewWalletCheckNumber: UIImageView!
    @IBOutlet weak var viewWallet: UIView!

    @IBOutlet weak var addressViewHeight: NSLayoutConstraint!
    var addressString = ""

    var exchange: Decimal?

    var exchangeIn: Decimal?, exchangeOut: Decimal?, minAmount: Int?, maxAmount: Int?


    var numberWalletIsEmpty = true
    var amountStringIsEmpty = true

    var amountRubString = ""
    var amountCryptoString = ""

    @IBAction func onSendClicked(_ sender: Any) {
//        showAddressInfo()
        if addressTextField.text != nil && addressTextField.text!.isValidBitcoinAddress() {
            NotificationCenter.default.post(name: NSNotification.Name("sendCoins"), object: nil)
            TransactionManager.instance.sendBitcoins(to: addressTextField.text!, amount: 600)
        }
    }

    func showAddressInfo() {
        Config.QR_CODE_ADDRESS = addressString
        if let bitcoinInfoView = storyboard?.instantiateViewController(withIdentifier: "BitcoinAddressInfoViewController") as? BitcoinAddressInfoViewController {
            present(bitcoinInfoView, animated: true)
        }
    }

    func amountRubChanged(_ rubTextField: UITextField) {
        amountRubString = rubTextField.text!

        if (amountRubString.contains(",")) {
            amountRubString = amountRubString.replacingOccurrences(of: ",", with: ".")
        }

        rubTextField.text! = amountRubString

        if exchangeIn != nil {
            if (!amountRubString.isEmpty && amountRubString != ".") {
                amountCryptoTextField.text = ("\(Decimal(string: amountRubString)! / exchangeIn!)")
            } else {
                amountCryptoTextField.text = ""
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
                amountRubTextField.text = ("\(Decimal(string: amountCryptoString)! * exchangeIn!)")
            } else {
                amountRubTextField.text = ""
            }
        }
    }

    func addressChanged(_ numberWalletTextFiled: UITextField) {
        checkAddress()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

//        self.updateExchangeRate()

        if Config.QR_CODE_VALUE != nil && !Config.QR_CODE_VALUE.isEmpty {

            addressTextField.text = Config.QR_CODE_VALUE
            self.checkAddress()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        Config.QR_CODE_VALUE = ""
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        amountRubTextField.isEnabled = false
        amountCryptoTextField.isEnabled = false
        exchangeIn = 0.234

        hintLabel.text = "Make sure that the purse of the recipient is correct. To do this, click on the icon on the right.".localized
        addressTextField.placeholder = "Bitcoin address".localized
        sendButton.setTitle("SEND".localized, for: .normal)

        sendButton.layer.cornerRadius = 15

        viewWallet.clipsToBounds = true
        viewWallet.layer.cornerRadius = 5
        viewWalletHeight.constant = 0

        amountRubTextField.addTarget(self, action: #selector(amountRubChanged(_:)), for: .editingChanged)
        amountCryptoTextField.addTarget(self, action: #selector(amountCryptoChanged(_:)), for: .editingChanged)
        addressTextField.addTarget(self, action: #selector(addressChanged(_:)), for: .editingChanged)

        let tapCross = UITapGestureRecognizer(target: self, action: #selector(closeWalletView))
        tapCross.numberOfTapsRequired = 1 // you can change this value
        crossButton.isUserInteractionEnabled = true
        crossButton.addGestureRecognizer(tapCross)

    }

    func updateExchangeRate() {
        TransactionManager.instance.exchangeRateTask(from: .RUR, to: .BTC) { (exchangeIn, exchangeOut, minAmount, maxAmount) in
            if exchangeIn != nil && exchangeOut != nil && minAmount != nil && maxAmount != nil {
                self.exchangeIn = exchangeIn
                self.exchangeOut = exchangeOut
                self.minAmount = minAmount
                self.maxAmount = maxAmount

                print("Exchange rates: \(exchangeIn!)!")

                self.amountRubTextField.isEnabled = true
                self.amountCryptoTextField.isEnabled = true

            } else {
                DispatchQueue.main.async {
                    print("Error: failed to laod exchange rate")

                }
            }
        }
    }

    func checkAddress() {
        if !addressTextField.text!.isEmpty {
            addressString = addressTextField.text!
            if addressString.starts(with: "1") && addressString.count >= 25 && addressString.count <= 34 {
                if addressString.isValidBitcoinAddress() {

                    viewWalletHeight.constant = 80
                    viewWallet.isHidden = false
                    addressViewHeight.constant = 0;

                    let tapKey = UITapGestureRecognizer(target: self, action: #selector(showAddressInfo))
                    tapKey.numberOfTapsRequired = 1 // you can change this value
                    keyButton.isUserInteractionEnabled = true
                    keyButton.addGestureRecognizer(tapKey)

                }
            }
        }
    }

    func closeWalletView() {
        viewWalletHeight.constant = 0
        viewWallet.isHidden = true
        addressViewHeight.constant = 40
        addressTextField.text = ""
    }
}
