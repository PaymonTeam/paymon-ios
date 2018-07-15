//
//  SettingsSecurityTableViewController.swift
//  paymon
//
//  Created by maks on 30.09.17.
//  Copyright © 2017 Paymon. All rights reserved.
//

import UIKit

class SettingsSecurityTableViewController: UITableViewController {

    @IBOutlet weak var passwordProtectedCell: UITableViewCell!
    @IBOutlet weak var enterPasswordCell: UITableViewCell!
    @IBOutlet weak var subTitlePasswordProtectedCell: UILabel!
    
    let switchPasswordProtected = UISwitch()


    override func viewDidLoad() {
        super.viewDidLoad()

        passwordProtectedCell.textLabel!.text! = "Password protect".localized
        subTitlePasswordProtectedCell.text = "Set the password for the application".localized
        enterPasswordCell.textLabel!.text! = "Enter password".localized

        passwordProtectedCell.accessoryView = switchPasswordProtected

        switchPasswordProtected.addTarget(self, action: #selector(segmentControlChangeValue(_:)), for: .valueChanged)

        loadSettings()

    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        switch (section) {
        case 0: return "Protect".localized
        default: return "Other".localized
        }
    }

    func segmentControlChangeValue(_ segmentControl : UISegmentedControl) {
        if switchPasswordProtected.isOn == false {
            User.securityPasswordProtectedString = ""

            User.saveSecuritySettings()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        saveSettings()

    }

    func loadSettings() {

        switchPasswordProtected.setOn(User.securitySwitchPasswordProtected, animated: true)

    }

    func saveSettings () {
        User.securitySwitchPasswordProtected = switchPasswordProtected.isOn

        if (switchPasswordProtected.isOn == false) {
            User.securityPasswordProtectedString = ""
        }

        User.saveSecuritySettings()
    }
}
