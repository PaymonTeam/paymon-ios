//
//  UIView+Loading.swift
//  paymon
//
//  Created by Jogendar Singh on 08/07/18.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import UIKit
import MBProgressHUD

/// loding constant which will show on loadingView
let kLoading = "Loading"

extension UIView {

    /// To show the loading on view
    func showLoading() {
        guard (self.subviews.last is MBProgressHUD) == false else { return }
        let progressHud = MBProgressHUD.showAdded(to: self, animated: false)
        progressHud.label.text = kLoading
    }
    /// To hide the loading from view
    func hideLoading() {
        MBProgressHUD.hide(for: self, animated: true)
    }
    /// To show the loading on window
    func showLoadingOnWindow() {
        if let app = UIApplication.shared.delegate as? AppDelegate, let window = app.window {
            let progressHud = MBProgressHUD.showAdded(to: window, animated: false)
            progressHud.label.text = kLoading
        }
    }
    /// To hide the loading from window
    func hideLoadingOnWindow() {
        if let app = UIApplication.shared.delegate as? AppDelegate, let window = app.window {
            MBProgressHUD.hide(for: window, animated: true)
        }
    }
}

