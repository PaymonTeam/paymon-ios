//
// Created by maks on 05.11.17.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import Foundation
import UIKit

class InviteFriendsViewController : UIViewController {
    @IBOutlet weak var titleOneLabel: UILabel!
    @IBOutlet weak var titleTwoLabel: UILabel!
    @IBOutlet weak var hintLabel: UILabel!
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    @IBOutlet weak var pictureImageView: UIImageView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var codeTextField: UITextField!
    @IBAction private func onNavBarItemLeftClicked() {
        dismiss(animated: true)
    }

    var inviteString = ""
    var urlPaymon : NSURL! = NSURL(string: "http://paymon.org")

    @IBAction func startShareActivity(_ sender: Any) {
        let shareActivity = UIActivityViewController(activityItems: [inviteString, urlPaymon], applicationActivities: [])

        shareActivity.popoverPresentationController?.sourceView = self.view
        shareActivity.popoverPresentationController?.sourceRect = self.view.bounds

        present(shareActivity, animated: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        if let user = User.currentUser {
            codeTextField.text = user.inviteCode
            inviteString = String(format: NSLocalizedString("Hi! Install and register on this code '%@' in the app and get free cryptocurrency from Paymon!", comment: ""), codeTextField.text!)
        }

        shareButton.layer.cornerRadius = 15
        let navigationItem = UINavigationItem()
        let leftButton = UIBarButtonItem(image: UIImage(named: "nav_bar_item_arrow_left"), style: .plain, target: self, action: #selector(onNavBarItemLeftClicked))
        navigationItem.leftBarButtonItem = leftButton
        navigationItem.title = "Invite Friends".localized
        navigationBar.items = [navigationItem]

        titleOneLabel.text = "Invite your friends in Paymon and receive additional rewards after the end of ICO".localized
        titleTwoLabel.text = "The more people will register with your invite сode, the more will be your reward".localized

        hintLabel.text = "Your invite code".localized

        shareButton.setTitle("share".localized, for: .normal)

    }
}
