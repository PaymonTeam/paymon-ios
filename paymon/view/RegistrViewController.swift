//
// Created by maks on 16.11.17.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import UIKit

class RegistrViewController : UIViewController {

    @IBOutlet weak var borderConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var registrIndicator: UIActivityIndicatorView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var goToStartViewButton: UIButton!
    private var observerCanRegistrTrue : NSObjectProtocol!
    private var observerCanRegistrFalse : NSObjectProtocol!
    private var observerRegistrHideIndicator : NSObjectProtocol!
    private var observerRegistrButton : NSObjectProtocol!
    private var observerRegistrFalse : NSObjectProtocol!



    var canRegistr = false


    @IBAction func goToStartView(_ sender: Any) {
        dismiss(animated: true)
    }

    @IBAction private func onNavBarItemLeftClicked() {
        dismiss(animated: true)
    }

    func stopIndicator(notofication: Notification) {
        DispatchQueue.main.async() {
            self.registrIndicator.stopAnimating()
        }
    }

    func onNavBarItemRightClicked(){
        NotificationCenter.default.post(name: NSNotification.Name("registr"), object: nil)

        if (canRegistr) {

            updateNavigationBar(visibleRight: false)

            DispatchQueue.main.async() {
                self.registrIndicator.startAnimating()
            }
            self.view.endEditing(true)
        }
    }

    func updateNavigationBar(visibleRight: Bool) {

        DispatchQueue.main.async() {
//            let navigationItem = UINavigationItem()

            let leftButton = UIBarButtonItem(image: UIImage(named: "nav_bar_item_arrow_left"), style: .plain, target: self, action: #selector(self.onNavBarItemLeftClicked))
            let rightButton = UIBarButtonItem(image: UIImage(named: "check"), style: .plain, target: self, action: #selector(self.onNavBarItemRightClicked))

            self.navigationItem.leftBarButtonItem = leftButton

            self.navigationItem.title = "Registration".localized

            if (!visibleRight) {
                self.navigationItem.rightBarButtonItem = nil
            } else {
                self.navigationItem.rightBarButtonItem = rightButton
            }

            self.navigationBar.items = [self.navigationItem]
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        observerRegistrFalse = NotificationCenter.default.addObserver(forName: NSNotification.Name("registrFalse"), object: nil, queue: nil) {
            notification in

            self.updateNavigationBar(visibleRight: true)
        }

        observerRegistrButton = NotificationCenter.default.addObserver(forName: NSNotification.Name("clickRegistrButton"), object: nil, queue: nil) {
            notification in

            self.onNavBarItemRightClicked()
        }

        observerCanRegistrTrue = NotificationCenter.default.addObserver(forName: NSNotification.Name("canRegistrTrue"), object: nil, queue: nil) {
            notification in

            self.canRegistr = true

            self.updateNavigationBar(visibleRight: true)
        }

        observerCanRegistrFalse = NotificationCenter.default.addObserver(forName: NSNotification.Name("canRegistrFalse"), object: nil, queue: nil) {
            notification in

            self.canRegistr = false

            self.updateNavigationBar(visibleRight: false)

        }

        observerRegistrHideIndicator = NotificationCenter.default.addObserver(forName: NSNotification.Name("hideIndicatorRegistr"), object: nil, queue: nil, using: stopIndicator)


    }

    override func viewDidLoad() {
        super.viewDidLoad()

        canRegistr = false

        updateNavigationBar(visibleRight: false)

        goToStartViewButton.setTitle("I already have an account".localized, for: .normal)

        borderConstraint.constant = 0.5

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(observerCanRegistrTrue)
        NotificationCenter.default.removeObserver(observerCanRegistrFalse)
        NotificationCenter.default.removeObserver(observerRegistrFalse)
        NotificationCenter.default.removeObserver(observerRegistrHideIndicator)
        NotificationCenter.default.removeObserver(observerRegistrButton)


    }
}
