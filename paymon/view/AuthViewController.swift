//
//  AuthViewController.swift
//  paymon
//
//  Created by maks on 07.10.17.
//  Copyright © 2017 Paymon. All rights reserved.
//

import UIKit

class AuthViewController: UIViewController {
    var canLogin = false

    @IBOutlet weak var borderConstraint: NSLayoutConstraint!
    @IBOutlet weak var indicatorLogin: UIActivityIndicatorView!
    @IBOutlet weak var navigationBar: UINavigationBar!

    private var observerLoginHideIndicator : NSObjectProtocol!
    private var observerLoginFalse : NSObjectProtocol!
    private var observerCanLoginTrue : NSObjectProtocol!
    private var observerCanLoginFalse : NSObjectProtocol!
    private var observerReturnKeyLogin : NSObjectProtocol!

    @IBAction private func onNavBarItemLeftClicked() {
        dismiss(animated: true)
    }

    func stopIndicator(notofication: Notification) {
        DispatchQueue.main.async() {
            self.indicatorLogin.stopAnimating()
        }
    }

    @IBAction private func onNavBarItemRightClicked() {

        NotificationCenter.default.post(name: NSNotification.Name("login"), object: nil)

        if (canLogin) {

            updateNavigationBar(visibleRight: false)

            DispatchQueue.main.async() {
                self.indicatorLogin.startAnimating()
            }
            self.view.endEditing(true)
        }
    }

    func updateNavigationBar(visibleRight: Bool) {

        DispatchQueue.main.async {
//            let navigationItem = UINavigationItem()

            let leftButton = UIBarButtonItem(image: UIImage(named: "nav_bar_item_arrow_left"), style: .plain, target: self, action: #selector(self.onNavBarItemLeftClicked))
            let rightButton = UIBarButtonItem(image: UIImage(named: "login"), style: .plain, target: self, action: #selector(self.onNavBarItemRightClicked))

            self.navigationItem.leftBarButtonItem = leftButton

            self.navigationItem.title = "Sign In".localized

            if (!visibleRight) {
                self.navigationItem.rightBarButtonItem = nil
            } else {
                self.navigationItem.rightBarButtonItem = rightButton
            }

            self.navigationBar.items = [self.navigationItem]
        }
    }

    func changeStatusLogin(canLogin: Bool) {
        self.canLogin = canLogin
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        observerReturnKeyLogin = NotificationCenter.default.addObserver(forName: NSNotification.Name("returnKeyLogin"), object: nil, queue: nil) {
            notification in

            self.onNavBarItemRightClicked()
        }

        observerLoginFalse = NotificationCenter.default.addObserver(forName: NSNotification.Name("loginFalse"), object: nil, queue: nil) {
            notification in

            self.updateNavigationBar(visibleRight: true)
        }
        observerLoginHideIndicator = NotificationCenter.default.addObserver(forName: NSNotification.Name("hideIndicatorLogin"), object: nil, queue: nil, using: stopIndicator)

        observerCanLoginTrue = NotificationCenter.default.addObserver(forName: NSNotification.Name("canLoginTrue"), object: nil, queue: nil) {
            notification in

            self.changeStatusLogin(canLogin: true)
        }

        observerCanLoginFalse = NotificationCenter.default.addObserver(forName: NSNotification.Name("canLoginFalse"), object: nil, queue: nil) {
            notification in

            self.changeStatusLogin(canLogin: false)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()


        borderConstraint.constant = 0.5
        
        canLogin = false
        updateNavigationBar(visibleRight: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(observerLoginHideIndicator)
        NotificationCenter.default.removeObserver(observerLoginFalse)
        NotificationCenter.default.removeObserver(observerCanLoginTrue)
        NotificationCenter.default.removeObserver(observerCanLoginFalse)
        NotificationCenter.default.removeObserver(observerReturnKeyLogin)
    }
}
