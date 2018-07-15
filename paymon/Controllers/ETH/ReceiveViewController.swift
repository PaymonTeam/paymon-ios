//
//  ReceiveViewController.swift
//  paymon
//
//  Created by Jogendar Singh on 26/06/18.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import Foundation
class ReceiveViewController: UIViewController {
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var copyAddressButton: UIButton!



    // MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
    }

    func setupData() {
        if let address = UserDefaults.instance.getEthernAddress(), !address.isEmpty {
            addressLabel.text = address
            let image = try? QRService().createQR(fromString: address, size: CGSize(width: 300, height: 300))
            qrImageView.image = image
        }

    }
    // MARK: Actions

    @IBAction func copyAddressPressed() {
        let alert = UIAlertController(title: title, message: "You address is copied to clipboard", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] action in
            guard let address = self?.addressLabel.text else { return }
            UIPasteboard.general.string = address
            self?.navigationController?.popViewController(animated: true)

        }))
        present(alert, animated: true, completion: nil)

    }

}
