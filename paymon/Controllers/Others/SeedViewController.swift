//
// Created by Vladislav on 03/11/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import UIKit
import Foundation

extension Character {
    func unicodeScalarCodePoint() -> UInt32 {
        let characterString = String(self)
        let scalars = characterString.unicodeScalars

        return scalars[scalars.startIndex].value
    }
}

class SeedViewController : UIViewController {
//    @property (nonatomic, strong) IBOutlet UILabel *seedLabel, *writeLabel;
//    @property (nonatomic, strong) IBOutlet UIButton *writeButton;
//    @property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
//    @property (nonatomic, strong) IBOutlet UIBarButtonItem *remindButton, *doneButton;
//    @property (nonatomic, strong) IBOutlet UIImageView *wallpaper;
    @IBOutlet weak var seedLabel: UILabel!
    @IBOutlet weak var toolbar: UIToolbar!
    
    var seedPhrase:String!
    var _authSuccess:Bool = false
    var resignActiveObserver:NSObjectProtocol!
    var screenshotObserver:NSObjectProtocol!

    @IBOutlet weak var navBarItem: UIBarButtonItem!
    @IBOutlet weak var hintLabel: UILabel!
    @IBOutlet weak var titleOneLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        navBarItem.title = "OK".localized
        navBarItem.action = #selector(done)

        titleOneLabel.text="if you ever lose your phone, you will need this phrase to recover your Bitcoin wallet".localized
        hintLabel.text = "please write it down".localized

        guard let manager = BRWalletManager.sharedInstance() else {
            return
        }

        if manager.noWallet {
            seedPhrase = manager.generateRandomSeed()
            BRPeerManager.sharedInstance()?.connect()
        //            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:WALLET_NEEDS_BACKUP_KEY];
        //            [[NSUserDefaults standardUserDefaults] synchronize];
        } else {
            seedPhrase = manager.seedPhrase
        }

        if seedPhrase.count > 0 {
            _authSuccess = true;
        }

//        self.doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"done", nil)
//                           style:UIBarButtonItemStylePlain target:self action:@selector(done:)];

        autoreleasepool {
    // @autoreleasepool ensures sensitive data will be dealocated immediately
        if seedPhrase.count > 0 && (seedPhrase[seedPhrase.index(seedPhrase.startIndex, offsetBy: 0)] as Character).unicodeScalarCodePoint() > 0x3000 {
                // ideographic language
            var r = CGRect.zero
            var s: String = ""//CFStringCreateMutable(SecureAllocator(), 0) as String
            var l: String = ""//CFStringCreateMutable(SecureAllocator(), 0) as String

            let arr:[String.SubSequence] = seedPhrase.split(separator: " ") //CFStringCreateArrayBySeparatingStrings(SecureAllocator(), (seedPhrase as CFString), " " as CFString)
//            let lines = arr as! [CTLine]
            for w in arr {
//            for ln in lines {
//                let w = ln as! String
//            for w: String in CFStringCreateArrayBySeparatingStrings(SecureAllocator(), (seedPhrase as CFString), " " as CFString) {
                if l.count > 0 {
                    l += "\u{3000}"
                }
                l += w

                r = l.boundingRect(with: CGRect.infinite.size, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: seedLabel.font]/* as? [NSAttributedStringKey : Any]*/, context: nil)
                if r.size.width + 20.0 * 2.0 >= view.bounds.size.width {
                    s += "\n"
                    l = String(w)
                }
                else if s.count > 0 {
                    s += "\u{3000}"
                }

                s += w
            }
            seedLabel.text = s
        } else {
            seedLabel.text = seedPhrase
        }
        seedPhrase = nil
    }


    #if DEBUG
        self.seedLabel.isUserInteractionEnabled = true // allow clipboard copy only for debug builds
    #endif
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        var delay: TimeInterval = 15.0
        UIApplication.shared.setStatusBarStyle(.default, animated: true)
        // remove done button if we're not the root of the nav stack
//        if navigationController?.viewControllers.first != self {
//            toolbar.isHidden = true
//        } else {
//            delay *= 2
//        }
        // extra delay before showing toggle when starting a new wallet
        if UserDefaults.standard.bool(forKey: WALLET_NEEDS_BACKUP_KEY) {
            perform(#selector(self.showWriteToggle), with: nil, afterDelay: delay)
        }
        UIView.animate(withDuration: 0.1, animations: {() -> Void in
            self.seedLabel.alpha = 1.0
        })
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if resignActiveObserver == nil {
            resignActiveObserver = NotificationCenter.default.addObserver(forName: .UIApplicationWillResignActive, object: nil, queue: nil, using: { (_ note: Notification) -> Void in
                if self.navigationController?.viewControllers.first != self {
                    self.navigationController?.popViewController(animated: false)
                }
            })
        }

        //TODO: make it easy to create a new wallet and transfer balance
        if screenshotObserver == nil {
            screenshotObserver = NotificationCenter.default.addObserver(forName: .UIApplicationUserDidTakeScreenshot, object: nil, queue: nil, using: { (_ note: Notification) -> Void in
                if self.navigationController?.viewControllers.first != self {
                    UIAlertView(title: NSLocalizedString("WARNING", comment: ""), message: NSLocalizedString("Screenshots are visible to other apps and devices.\nYour funds are at risk. Transfer your balance to another wallet.\n", comment: ""), delegate: nil, cancelButtonTitle: NSLocalizedString("ok", comment: ""), otherButtonTitles: "").show()
                } else {
                    BRWalletManager.sharedInstance()?.seedPhrase = nil
                    self.navigationController?.presentingViewController?.dismiss(animated: false)
                    UIApplication.shared.setStatusBarStyle(.lightContent, animated: true)
                    UIAlertView(title: NSLocalizedString("WARNING", comment: ""), message: NSLocalizedString("Screenshots are visible to other apps and devices.\nGenerate a new recovery phrase and keep it secret.", comment: ""), delegate: nil, cancelButtonTitle: "", otherButtonTitles: NSLocalizedString("ok", comment: "")).show()
                }
            })
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.seedLabel.text = ""
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        if resignActiveObserver != nil {
            NotificationCenter.default.removeObserver(resignActiveObserver)
        }
        if screenshotObserver != nil {
            NotificationCenter.default.removeObserver(screenshotObserver)
        }
    }

    deinit {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        if resignActiveObserver != nil {
            NotificationCenter.default.removeObserver(resignActiveObserver)
        }
        if screenshotObserver != nil {
            NotificationCenter.default.removeObserver(screenshotObserver)
        }
    }

    func showWriteToggle() {
//        writeButton.alpha = 0.0
//        writeLabel.alpha = writeButton.alpha
//        writeButton.hidden = false
//        writeLabel.hidden = writeButton.hidden
//        UIView.animate(withDuration: 0.5, animations: {() -> Void in
//            self.writeButton.alpha = 1.0
//            self.writeLabel.alpha = self.writeButton.alpha
//        })
    }

    // MARK: - IBAction

    @IBAction func done() {
        dismiss(animated: true)
    }

//    @IBAction func done() {
//        [BREventManager saveEvent:@"seed:dismiss"];
//        if (self.navigationController.viewControllers.firstObject != self) return;
//
//        self.navigationController.presentingViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
//        [self.navigationController.presentingViewController.presentingViewController dismissViewControllerAnimated:YES
//         completion:nil];
//    }
/*

    - (IBAction)toggleWrite:(id)sender
    {
        [BREventManager saveEvent:@"seed:toggle_write"];
        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];

        if ([defs boolForKey:WALLET_NEEDS_BACKUP_KEY]) {
            [self.toolbar setItems:@[self.toolbar.items[0], self.doneButton] animated:YES];
            [self.writeButton setImage:[UIImage imageNamed:@"checkbox-checked"] forState:UIControlStateNormal];
            [defs removeObjectForKey:WALLET_NEEDS_BACKUP_KEY];
        } else {
            [self.toolbar setItems:@[self.toolbar.items[0], self.remindButton] animated:YES];
            [self.writeButton setImage:[UIImage imageNamed:@"checkbox-empty"] forState:UIControlStateNormal];
            [defs setBool:YES forKey:WALLET_NEEDS_BACKUP_KEY];
        }

        [defs synchronize];
    }
    */
}
