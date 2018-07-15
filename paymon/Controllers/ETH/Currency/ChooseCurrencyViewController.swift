//
//  ChooseCurrencyViewController.swift
//  paymon
//
//  Created by Jogendar Singh on 01/07/18.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import UIKit

protocol SelectedCurrencyDelegate: class {
    func selectedCurrency(value: String)
}

class ChooseCurrencyViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var delegate: SelectedCurrencyDelegate?
    // MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}

// MARK: - TableView

extension ChooseCurrencyViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChooseCurrencyCell", for: indexPath)
        cell.textLabel?.text = Wallet.supportedCurrencies[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.selectedCurrency(value: Wallet.supportedCurrencies[indexPath.row])
        self.navigationController?.popViewController(animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Wallet.supportedCurrencies.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "CURRENCY"
    }

}

