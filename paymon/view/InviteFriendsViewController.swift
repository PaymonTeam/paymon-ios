//
// Created by maks on 05.11.17.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

class InviteFriendsViewController : UIViewController, MFMailComposeViewControllerDelegate {
    @IBOutlet weak var titleOneLabel: UILabel!
    @IBOutlet weak var titleTwoLabel: UILabel!
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
    
//    private func mailComposeController(controller: MFMailComposeViewController,
//                               didFinishWithResult result: MFMailComposeResult, error: MFMailComposeError) {
//
//        print("dismiss controller")
//
//        controller.dismiss(animated: true, completion: nil)
//    }
    
    
    @IBAction func writeEmail(_ sender: Any) {
        
        let emailTitle = "Feedback"
        let messageBody = ""
        let toRecipents = ["support@paymon.org"]
        let mc = MFMailComposeViewController()
        mc.mailComposeDelegate = self
        mc.setSubject(emailTitle)
        mc.setMessageBody(messageBody, isHTML: false)
        mc.setToRecipients(toRecipents)

        if (MFMailComposeViewController.canSendMail()) {
            self.present(mc, animated: true, completion: nil)
        } else {
            showSendMailErrorAlert()
        }
    }
    
    func showSendMailErrorAlert() {
        
        let sendMailErrorAlert = UIAlertController(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", preferredStyle: .alert)
        sendMailErrorAlert.show(self, sender: nil)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        if let user = User.currentUser {
            codeTextField.text = user.inviteCode
            inviteString = String(format: NSLocalizedString("Hi! Install and register on this code '%@' in the app and get free cryptocurrency from Paymon!", comment: ""), codeTextField.text!)
        }

        shareButton.layer.cornerRadius = 15
        let navigationItem = UINavigationItem()
        let leftButton = UIBarButtonItem(image: UIImage(named: "nav_bar_item_arrow_left"), style: .done, target: self, action: #selector(onNavBarItemLeftClicked))
        navigationItem.leftBarButtonItem = leftButton
        navigationItem.title = "Invite Friends".localized
        navigationBar.items = [navigationItem]

        titleOneLabel.text = "Invite your friends to Paymon and help us develop".localized
        titleTwoLabel.text = "Write feedback and shortcomings to our official email address".localized

        shareButton.setTitle("share".localized, for: .normal)

    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)

    }
}
