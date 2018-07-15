//
//  CoinDetailsViewController.swift
//  paymon
//
//  Created by Jogendar Singh on 24/06/18.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import Foundation

class CoinDetailsViewController: UIViewController {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!

    // MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "nav_bar_item_arrow_left"), style: .plain, target: self, action: #selector(actionBackButton))
    }

    // MARK: Actions
    @objc func actionBackButton() {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func sendPressed(_ sender: UIButton) {
        let recieveEthernVC = StoryBoard.ethur.instantiateViewController(withIdentifier: StoryBoardIdentifier.sendVCStoryID)
        self.navigationController?.pushViewController(recieveEthernVC, animated: true)

    }

    @IBAction func receivePressed(_ sender: UIButton) {
        let recieveEthernVC = StoryBoard.ethur.instantiateViewController(withIdentifier: StoryBoardIdentifier.receiveEthernVC)
        self.navigationController?.pushViewController(recieveEthernVC, animated: true)
    }

}

