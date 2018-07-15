//
// Created by Vladislav on 20/09/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import Foundation

class MoneyWithdrawView : UIViewController, UITableViewDelegate, UITableViewDataSource, UIWebViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    var ymBalance:Double?
    var webV:UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        if User.ymAccessToken == nil {
            self.ymBalance = nil
        } else {
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        
        if User.ymAccessToken == nil {
            let cell = tableView.dequeueReusableCell(withIdentifier: "YMWithdrawMethodAddTableCell") as! YMAddTableCell
            cell.titleLabel.text = "Add Yandex wallet".localized
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "YMWithdrawMethodTableCell") as! YMTableCell
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
                if let controller = storyboard?.instantiateViewController(withIdentifier: "YMWithdrawViewController") as? YMWithdrawViewController {
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
        
        if let url = request.url {
            print(url.path, url)
            if url.description.starts(with: TransactionManager.instance.YM_REDIRECT_URI) {
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
