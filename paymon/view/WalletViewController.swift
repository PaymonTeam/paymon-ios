//
// Created by Vladislav on 20/09/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

class WalletViewController : UIViewController {
    @IBOutlet weak var segmentControl: UISegmentedControl!
    private weak var _content: UIViewController!

    private var observerSendCoins : NSObjectProtocol!
    private var observerTransferSuccess : NSObjectProtocol!

    @IBOutlet weak var sendCoinsIndicator: UIActivityIndicatorView!
    let scanButton = UIBarButtonItem(image: UIImage(named: "camera"), style: .plain, target: self, action: #selector(onScanClick))
    let infoButton = UIBarButtonItem(image: UIImage(named: "info_circle"), style: .plain, target: self, action: #selector(onInfoClick))
    let leftButton = UIBarButtonItem(image: UIImage(named: "nav_bar_item_arrow_left"), style: .plain, target: self, action: #selector(onNavBarItemLeftClicked))

    weak var content: UIViewController! {
        set(newContent) {
            if _content != nil {
                _content.view.removeFromSuperview()
                _content.removeFromParentViewController()
            }
            _content = newContent
//            _content.view.translatesAutoresizingMaskIntoConstraints = false


//            _content.view.frame.origin.y = 65
//            _content.view.frame.size.height -= 65

            self.addChildViewController(_content)
//            print("HORIZONTAL")
//            for c in content.view.constraintsAffectingLayout(for: .horizontal) {
//                print(c)
//            }
//            print("VERTICAL")
//            for c in content.view.constraintsAffectingLayout(for: .vertical) {
//                print(c)
//            }

            self.view.addSubview(_content.view)

//            let leadingConstraint = _content.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
//            let trailingConstraint = _content.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
//            let topConstraint = _content.view.topAnchor.constraint(equalTo: self.view.topAnchor)
//            let bottomConstraint = _content.view.bottomAnchor.constraint(equalTo: self.view.topAnchor, constant: -50)
//            let initialConstraints = [leadingConstraint, trailingConstraint, topConstraint, bottomConstraint]
//
//            NSLayoutConstraint.activate(initialConstraints)

            _content.didMove(toParentViewController: self)

            _content.view.frame.origin.y = 75
            _content.view.frame.size.height -= 75

        }
        get {
            return _content
        }
    }

    @IBOutlet weak var navigationBar: UINavigationBar!

    @IBAction private func onNavBarItemLeftClicked() {
        dismiss(animated: true)
    }

    func stopIndicator(notofication : Notification) {
        DispatchQueue.main.async() {
            self.sendCoinsIndicator.stopAnimating()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        observerSendCoins = NotificationCenter.default.addObserver(forName: NSNotification.Name("sendCoins"), object: nil, queue: nil ){ notification in

            DispatchQueue.main.async() {
                self.updateNavigationBar(visibleScan: false)
                self.sendCoinsIndicator.startAnimating()

                //todo обработать ответ об отправке биктов и вывести AlertDialog
            }
        }

        observerTransferSuccess = NotificationCenter.default.addObserver(forName: NSNotification.Name("transferSuccess"), object: nil, queue: nil, using: stopIndicator)
        }

    override func viewDidLoad() {
        super.viewDidLoad()

        segmentControl.setTitle("Transfer".localized, forSegmentAt: 0)
        segmentControl.setTitle("Deposit".localized.localized, forSegmentAt: 1)
        segmentControl.setTitle("Withdraw".localized, forSegmentAt: 2)

        navigationItem.titleView = segmentControl

        segmentControl.selectedSegmentIndex = 0
        self.onSegmentValueChanged(segmentControl)
    }

    func updateNavigationBar(visibleScan : Bool){

        navigationItem.titleView = segmentControl

        if (visibleScan) {
            navigationItem.rightBarButtonItem = scanButton
        } else {
            navigationItem.rightBarButtonItem = infoButton
        }

        navigationItem.leftBarButtonItem = leftButton
        navigationBar.setItems([navigationItem], animated: true)
    }

    func onScanClick() {
        if let scanController = storyboard?.instantiateViewController(withIdentifier: "ScanViewController") as? QRScannerViewController {
            present(scanController, animated: true)
        }
    }

    func onInfoClick() {
        switch segmentControl.selectedSegmentIndex {
            case 1:
                let infoAlertController = UIAlertController(title: "Want to deposit funds?".localized, message:
                "To Deposit funds to your Bitcoin wallet, select one of the suggested variants of deposit. To do this, please login  in E-wallet system and then fill in the form relevant data. Enjoy your use!".localized,
                        preferredStyle: UIAlertControllerStyle.alert)

                infoAlertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) in
                    infoAlertController.dismiss(animated: true, completion: nil)
                }))

                self.present(infoAlertController, animated: true, completion: nil)
            case 2:
                let infoAlertController = UIAlertController(title: "Want to withdraw funds?".localized, message:
                "To withdraw funds from Bitcoin wallet, select one of the options withdrawal. To do this, login to the E-wallet system, and then fill in the form relevant data. Enjoy your use!".localized,
                        preferredStyle: UIAlertControllerStyle.alert)

                infoAlertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) in
                    infoAlertController.dismiss(animated: true, completion: nil)
                }))

                self.present(infoAlertController, animated: true, completion: nil)
            default: print("Error of swgment control")
        }
    }

    @IBAction func onSegmentValueChanged(_ segment: UISegmentedControl) {
        let identifier:String
        switch segment.selectedSegmentIndex {
        case 2:
            identifier = "WalletWithdrawView"
            self.updateNavigationBar(visibleScan: false)
        case 1:
            identifier = "WalletDepositView"
            self.updateNavigationBar(visibleScan: false)
        case 0:
            identifier = "NewMoneyTransferView"
            self.updateNavigationBar(visibleScan: true)
        default:
            identifier = "NewMoneyTransferView"
        }
        content = storyboard?.instantiateViewController(withIdentifier: identifier)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        print("View will disappear")

        NotificationCenter.default.removeObserver(observerSendCoins)
        NotificationCenter.default.removeObserver(observerTransferSuccess)
    }
}
