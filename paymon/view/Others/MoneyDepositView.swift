//
// Created by Vladislav on 20/09/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

class YMTableCell : UITableViewCell {
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
}

class YMAddTableCell : UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
}

class MoneyDepositView : UIViewController, UITableViewDelegate, UITableViewDataSource, UIWebViewDelegate {
    @IBOutlet weak var qrImage: UIImageView!
    @IBOutlet weak var addressButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    var ymBalance:Double?
    var webV:UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        titleCellWallet.text = "Yandex money".localized
//        titleCellAddWallet.text = "Add Yandex wallet".localized

        tableView.delegate = self
        tableView.dataSource = self

//        if let manager = BRWalletManager.sharedInstance() {

            /*
        self.syncFinishedObserver =
            [[NSNotificationCenter defaultCenter] addObserverForName:BRPeerManagerSyncFinishedNotification object:nil
                                                               queue:nil usingBlock:^(NSNotification *note) {
                        if (self.timeout < 1.0) [self stopActivityWithSuccess:YES];
                        [self showBackupDialogIfNeeded];
                        if (! self.percent.hidden) [self hideTips];
                        self.percent.hidden = YES;
                        if (! manager.didAuthenticate) self.navigationItem.titleView = self.logo;
                        self.balance = manager.wallet.balance;
                        NSLog(@"Sync finished %@", manager.wallet.receiveAddress);
                        _balanceButton.titleLabel.text = manager.wallet.receiveAddress;
                    }];
        */
//        NSNotification.Name.BRPeerManagerSyncFinished
//        NotificationCenter.default.addObserver(forName: NSNotification.Name.BRPeerManagerSyncFinished, object: nil, queue:nil, using: { note in
//            self.addressButton.titleLabel!.text = manager.wallet!.receiveAddress!;
//            self.addressButton.setTitle(manager.wallet!.receiveAddress!, for: .normal)
//            if let groupDefs = UserDefaults(suiteName: "group.org.voisine.breadwallet") {
//                var image: UIImage!
//                if let req = BRPaymentRequest(string: manager.wallet!.receiveAddress!) {
////            if let req = BRPaymentRequest(string: groupDefs.string(forKey: "kBRSharedContainerDataWalletReceiveAddressKey")) {
////                    if let data = groupDefs.object(forKey: "kBRSharedContainerDataWalletQRImageKey") as? Data {
////                        if req.isValid {
////                            qrImage.image = UIImage(data: data)!.resize(qrImage.bounds.size, with: .none)
////                        }
////                    }
//
//                    if let data = groupDefs.object(forKey: "kBRSharedContainerDataWalletRequestDataKey") as? Data {
//                        if req.data == data {
//                            image = UIImage(data: data)
//                        }
//                    }
//
//                    if image == nil && req.data != nil {
//                        if let imgData = req.data {
//                            image = UIImage(qrCodeData: imgData, color: CIColor(red: 0.0, green: 0.0, blue: 0.0))
//                        }
//
//                    }
//
//                    if image != nil {
//                        qrImage.image = image.resize(qrImage.bounds.size, with: .none)
//                    }
//                }
//            }
//        }

        if User.ymAccessToken == nil {
            self.ymBalance = nil
        } else {
            TransactionManager.instance.getYMAccointInfo() { balance, _ in
                if let balance = balance {
                    self.ymBalance = balance
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
//                        self.tableView.beginUpdates()
//                        self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .middle)
//                        self.tableView.endUpdates()
                    }
                }
            }
        }

//self.qrImage = [image resize:(self.qrView ? self.qrView.bounds.size : CGSizeMake(250.0, 250.0))
//withInterpolationQuality:kCGInterpolationNone];
//        })
    }

//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//
//    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
//        let data = searchData[row]

        if User.ymAccessToken == nil {
            let cell = tableView.dequeueReusableCell(withIdentifier: "YMDepositMethodAddTableCell") as! YMAddTableCell
            cell.titleLabel.text = "Add Yandex wallet".localized
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "YMDepositMethodTableCell") as! YMTableCell
            cell.titleLabel.text = "Yandex money".localized
            if let balance = ymBalance {
                cell.balanceLabel.text = "₽\(balance)"
            } else {
                cell.balanceLabel.text = "..."
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            tableView.deselectRow(at: indexPath, animated: true)

            if cell is YMTableCell {
                if let controller = storyboard?.instantiateViewController(withIdentifier: "YMDepositViewController") as? YMDepositViewController {
//                    controller.modalPresentationStyle = .custom
//                    controller.modalTransitionStyle = .coverVertical
//                    presentModally
                    present(controller, animated: true)
                }
            } else {
                webV = UIWebView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
                webV.delegate = self
                self.view.addSubview(webV)
                TransactionManager.instance.initYM(webView: webV)
            }
        }
    }

    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        print("Webview fail with error \(error)");
    }

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        var shouldStartLoad = true

        if let url = request.url { //try? session.isRequest(request, toRedirectUrl: TransactionManager.instance.YM_REDIRECT_URI, authorizationInfo: authInfo) {
            print(url.path, url)
            if url.description.starts(with: TransactionManager.instance.YM_REDIRECT_URI) { //url.path == TransactionManager.instance.YM_REDIRECT_URI {
                shouldStartLoad = false
                guard let urlc = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return true }
                if let code = urlc.queryItems?.first(where: { $0.name == "code" })?.value {
                    _ = TransactionManager.instance.getYMAccessToken(webView: webV, code: code)
                    webView.removeFromSuperview()

                    TransactionManager.instance.getYMAccointInfo() { balance, _ in
                        if let balance = balance {
                            self.ymBalance = balance
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    }
                }
            }
        }
        return shouldStartLoad
    }
}
