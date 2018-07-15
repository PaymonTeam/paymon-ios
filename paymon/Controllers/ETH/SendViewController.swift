//
//  SendViewController.swift
//  paymon
//
//  Created by Jogendar Singh on 24/06/18.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import Foundation
import Geth
import web3swift

class SendViewController: UIViewController, QRCaptureDelegate, SelectedCurrencyDelegate {

    private var amount: Decimal = 0
    private var address: String!
    private var gasLimit: Decimal = Send.defaultGasLimit
    private var gasPrice: Decimal = Send.defaultGasPrice
    private var selectedCurrency = Wallet.defaultCurrency
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
    var transactionService: TransactionServiceProtocol!
    var rates: ETHModel?

    var client = GethEthereumClient()
    let context: GethContext = GethNewContext()
    let core = Ethereums.core

    var ethereumService: EthereumCoreProtocol!

    // MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        getRates()
//        getSuggestedGasPrice()
        startSynchronization()
    }
    func startSynchronization() {
        Ethereums.syncQueue.async { [unowned self] in
            do  {
//                let syncCoordinator = StandardSyncCoordinator()
//                core.syncCoordinator = syncCoordinator
                self.ethereumService = self.core
                try self.ethereumService.start(chain: Defaults.chain, delegate: nil)
                let keystore = appDelegate.keystore
                self.transactionService = TransactionService(core: self.core, keystore: keystore, transferType: .default, viewC: self)

            } catch {
                print("failed sync")
            }
        }

    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupKeyboardNotifications()
        amountTextField.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    func getRates() {
        ETHModel().getRates(success: { (response) in
            self.rates = response
            self.calculateTotalAmount()
        }) { (error) in
            print("")
        }
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
    func selectedCurrency(value: String) {
        selectedCurrency = value
        currencyButton.setTitle(value, for: UIControlState.normal)
        self.calculateTotalAmount()
    }

    // MARK: Actions

    @IBAction func sendPressed(_ sender: UIButton) {

        if let add = addressTextField.text {

            if let rateValue = rates?.getValueForSelected(currency: selectedCurrency) {
                let amountEther = amount.localToEther(rate: rateValue).toWei()
                
                self.view.showLoadingOnWindow()
                sendTransaction(amount: amountEther, to: add, gasLimit: gasLimit, gasPrice: gasPrice)
            }
        }
    }
    func sendTransaction(amount: Decimal, to: String, gasLimit: Decimal, gasPrice: Decimal) {
        do {
            let keychain = Keychain()
            let passphrase = try keychain.getPassphrase()
            let info = TransactionInfo(amount: amount, address: to, contractAddress: nil, gasLimit: gasLimit, gasPrice: gasPrice)
            transactionService.sendTransaction(with: info, passphrase: passphrase) { [weak self] result in
                self?.view.hideLoadingOnWindow()
                guard let `self` = self else { return }

                switch result {
                case .success(let sendedTransaction):
                    var transaction = Transaction.mapFromGethTransaction(sendedTransaction, time: Date().timeIntervalSince1970)
                    transaction.isPending = true
                    transaction.isIncoming = false
                    print("success")
                case .failure(let error):
                    // Need to add alert
                    print(error)
                }
            }
        } catch {
            print("exception accure")
        }
    }

    @IBAction func currencyPressed(_ sender: UIButton) {
        if let currencyVC = StoryBoard.ethur.instantiateViewController(withIdentifier: StoryBoardIdentifier.chooseCurrencyVCStoryID) as? ChooseCurrencyViewController {
            currencyVC.delegate = self
            self.navigationController?.pushViewController(currencyVC, animated: true)
        }
    }

    @IBAction func scanQRPressed(_ sender: UIButton) {

        if let scanController = StoryBoard.main.instantiateViewController(withIdentifier: "ScanViewController") as? QRScannerViewController {
            scanController.delegate = self
            present(scanController, animated: true)
        }

    }
    func qrCaptureDidDetect(object: AVMetadataMachineReadableCodeObject) {
        addressTextField.text = object.stringValue
    }

    @IBAction func addressDidChange(_ sender: UITextField) {

    }

    @IBAction func amountDidChange(_ sender: UITextField) {
        if let text = sender.text {
            let formated = text.replacingOccurrences(of: ",", with: ".")
            self.amount = Decimal(formated)
            calculateTotalAmount()
        }

    }

    @IBAction func gasLimitDidChange(_ sender: UITextField) {

    }

    func getSuggestedGasPrice() {
        do {
            let gasPrice = try self.client.suggestGasPrice(self.context)
            DispatchQueue.main.async {
                self.gasPrice = Decimal(gasPrice.getInt64())
                self.calculateTotalAmount()
            }
        } catch {
         print("")
        }
    }
    private func calculateTotalAmount() {
        let fee = gasLimit * gasPrice
        getCheckout(amount: amount, iso: selectedCurrency, fee: fee)
    }
    func didReceiveCheckout(amount: String, fiatAmount: String, fee: String, fiatFee: String) {
        amountLabel.text = amount
        localAmountLabel.text = fiatAmount
        feeLabel.text = fee
        localFeeLabel.text = fiatFee
    }
    func getCheckout(amount: Decimal, iso: String, fee: Decimal) {
        do {
            var rateValue = 0.0
            switch selectedCurrency {
            case "BTC":
                rateValue = self.rates?.BTC ?? 0.0
            case "CNY":
                rateValue = self.rates?.CNY ?? 0.0
            case "ETH":
                rateValue = self.rates?.ETH ?? 0.0
            case "EUR":
                rateValue = self.rates?.EUR ?? 0.0
            case "GBP":
                rateValue = self.rates?.GBP ?? 0.0
            case "USD":
                rateValue = self.rates?.USD ?? 0.0
            default:
                print("")
            }

            let feeAmount = Ether(weiValue: fee)
            let fiatFee = feeAmount.amount(in: iso, rate: rateValue)
            let rawLocalAmount = amount.localToEther(rate: rateValue).toWei()
            let ethAmount = Ether(weiValue: rawLocalAmount + fee)
            let fiatAmount = ethAmount.amount(in: iso, rate: rateValue)
            didReceiveCheckout(amount: ethAmount.amount, fiatAmount: fiatAmount, fee: feeAmount.amount, fiatFee: fiatFee)
        } catch let error {
            print("")
        }
    }
}
