//
//  ViewController.swift
//  paymon
//
//  Created by Vladislav on 11/08/2017.
//  Copyright © 2017 Paymon. All rights reserved.
//

import UIKit

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
}

class ViewController: UIViewController {
    var willAuth = false;

    override func viewDidLoad() {
        super.viewDidLoad()

//        NetworkManager.instance
//        let myView = ChatsView(frame: CGRect.zero)
//        self.view.addSubview(myView)
//        myView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero)

//        NetworkManager_Wrapper.instance.connect()
//        NetworkManager_Wrapper.instance.sendData(<#T##buffer: SerializedBuffer_Wrapper?##SerializedBuffer_Wrapper?#>, messageID: <#T##Int64##Swift.Int64#>)()
//        let conn = Connection.init(address: "127.0.0.1", port: 7968, interface: "")
//        conn?.delegate = ConnectionListener()
//        conn?.start()
//        let data = NSMutableData(capacity: 4)
//        let d = Data(bytes: [1,1,1,1])
//        data?.append(d)
//        conn?.send(data)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)



        if User.currentUser == nil {
            let startView = storyboard?.instantiateViewController(withIdentifier: "StartViewController") as! StartViewController
            present(startView, animated: true)
        } else if User.securitySwitchPasswordProtected && !User.securityPasswordProtectedString.isEmpty {
            let keyGuard = storyboard?.instantiateViewController(withIdentifier: "KeyGuardViewController") as! KeyGuardViewController
            present(keyGuard, animated: true)
        } else {
//            performSegue(withIdentifier: "TabsView", sender: nil)
            let tabBar = storyboard?.instantiateViewController(withIdentifier: "TabsView") as! TabsViewController
//            tabBar.selectedIndex = 1
            present(tabBar, animated: true)
        }

    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

